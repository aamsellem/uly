#!/bin/bash
# Démarre le serveur ULY et le tunnel Cloudflare en mode daemon (arrière-plan)
# Utilisé par /uly quand ULY_AUTO_START_TUNNEL=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/.daemon.pid"
LOG_FILE="$SCRIPT_DIR/daemon.log"
PORT="${SERVER_PORT:-8787}"

# Charger la configuration
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

# Fonction pour vérifier si l'API répond
api_is_healthy() {
    curl -s --max-time 2 "http://localhost:$PORT/health" >/dev/null 2>&1
}

# Fonction pour vérifier si les processus tournent
processes_running() {
    if [ -f "$PID_FILE" ]; then
        SERVER_PID=$(sed -n '1p' "$PID_FILE")
        TUNNEL_PID=$(sed -n '2p' "$PID_FILE")
        if kill -0 "$SERVER_PID" 2>/dev/null && kill -0 "$TUNNEL_PID" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

# Fonction pour récupérer l'URL du tunnel depuis les logs
get_tunnel_url() {
    if [ "$USE_NAMED_TUNNEL" = "true" ] && [ -n "$TUNNEL_NAME" ]; then
        echo "https://$TUNNEL_NAME.cfargotunnel.com"
    else
        grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' "$LOG_FILE" 2>/dev/null | tail -1
    fi
}

# Fonction pour enregistrer auprès de N8N
register_n8n() {
    local TUNNEL_URL="$1"
    if [ -z "$N8N_HOSTNAME" ]; then
        return 0
    fi
    if [ -z "$TUNNEL_URL" ]; then
        echo "N8N: URL tunnel manquante" >> "$LOG_FILE"
        return 1
    fi

    ULY_USER_NAME=$(git config user.name 2>/dev/null || id -F 2>/dev/null || echo "$USER")
    SESSION_ID="uly-$(date +%Y-%m-%d)"

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://${N8N_HOSTNAME}/webhook/uly-register" \
        -H "Content-Type: application/json" \
        -d "{\"hostname\": \"${TUNNEL_URL}\", \"name\": \"${ULY_USER_NAME}\", \"token\": \"${ULY_API_TOKEN}\", \"session_id\": \"${SESSION_ID}\"}" \
        2>/dev/null)

    if [ "$HTTP_CODE" = "200" ]; then
        echo "N8N: enregistré ($TUNNEL_URL)" >> "$LOG_FILE"
        return 0
    else
        echo "N8N: échec (HTTP $HTTP_CODE)" >> "$LOG_FILE"
        return 1
    fi
}

# Fonction pour tout arrêter proprement
stop_all() {
    if [ -f "$PID_FILE" ]; then
        SERVER_PID=$(sed -n '1p' "$PID_FILE")
        TUNNEL_PID=$(sed -n '2p' "$PID_FILE")
        kill "$SERVER_PID" 2>/dev/null
        kill "$TUNNEL_PID" 2>/dev/null
    fi
    # Nettoyer les processus orphelins
    pkill -f "python.*server.py" 2>/dev/null
    pkill -f "cloudflared.*tunnel.*$PORT" 2>/dev/null
    rm -f "$PID_FILE"
}

# Vérifier si tout tourne correctement
if processes_running && api_is_healthy; then
    # Toujours enregistrer auprès de N8N (l'URL peut avoir changé)
    TUNNEL_URL=$(get_tunnel_url)
    if [ -n "$N8N_HOSTNAME" ] && [ -n "$TUNNEL_URL" ]; then
        register_n8n "$TUNNEL_URL"
    fi
    echo "running"
    exit 0
fi

# Si partiellement up, tout arrêter et relancer
stop_all
sleep 1

# Vérifier que Claude Code est disponible
if ! command -v claude &> /dev/null; then
    echo "error: claude not found"
    exit 1
fi

# Vérifier que le setup a été fait
if [ ! -d "$SCRIPT_DIR/venv" ]; then
    echo "error: setup required - run ./.uly/integrations/cloudflare-tunnel/setup.sh first"
    exit 1
fi

# Vérifier que cloudflared est installé
if ! command -v cloudflared &> /dev/null; then
    echo "error: cloudflared not found - install with: brew install cloudflared"
    exit 1
fi

# Chemin vers python du venv
PYTHON="$SCRIPT_DIR/venv/bin/python"

# Vider les anciens logs
echo "=== Démarrage $(date) ===" > "$LOG_FILE"

# Démarrer le serveur API
cd "$SCRIPT_DIR"
nohup "$PYTHON" server.py >> "$LOG_FILE" 2>&1 &
SERVER_PID=$!

# Attendre que le serveur démarre et vérifier qu'il répond
echo "Attente du serveur API..." >> "$LOG_FILE"
for i in {1..10}; do
    if api_is_healthy; then
        break
    fi
    if ! kill -0 $SERVER_PID 2>/dev/null; then
        echo "error: server crashed - check daemon.log"
        exit 1
    fi
    sleep 1
done

# Vérification finale du serveur
if ! api_is_healthy; then
    kill $SERVER_PID 2>/dev/null
    echo "error: server not responding"
    exit 1
fi

echo "Serveur API OK (PID: $SERVER_PID)" >> "$LOG_FILE"

# Démarrer le tunnel Cloudflare
if [ "$USE_NAMED_TUNNEL" = "true" ]; then
    nohup cloudflared tunnel --config "$SCRIPT_DIR/config.yml" run >> "$LOG_FILE" 2>&1 &
    TUNNEL_PID=$!
else
    nohup cloudflared tunnel --url "http://localhost:$PORT" >> "$LOG_FILE" 2>&1 &
    TUNNEL_PID=$!
fi

sleep 3

# Vérifier que le tunnel est démarré
if ! kill -0 $TUNNEL_PID 2>/dev/null; then
    kill $SERVER_PID 2>/dev/null
    echo "error: tunnel failed - check daemon.log"
    exit 1
fi

echo "Tunnel OK (PID: $TUNNEL_PID)" >> "$LOG_FILE"

# Sauvegarder les PIDs
echo "$SERVER_PID" > "$PID_FILE"
echo "$TUNNEL_PID" >> "$PID_FILE"

# Attendre que l'URL soit disponible (quick tunnel)
TUNNEL_URL=""
for i in {1..20}; do
    TUNNEL_URL=$(get_tunnel_url)
    if [ -n "$TUNNEL_URL" ]; then
        break
    fi
    sleep 1
done

# Enregistrement N8N si configuré
if [ -n "$N8N_HOSTNAME" ]; then
    register_n8n "$TUNNEL_URL"
fi

if [ -n "$TUNNEL_URL" ]; then
    echo "URL: $TUNNEL_URL" >> "$LOG_FILE"
fi

echo "started"
exit 0
