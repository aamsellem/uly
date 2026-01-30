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

# Récupérer l'URL du tunnel
TUNNEL_URL=""
if [ "$USE_NAMED_TUNNEL" = "true" ] && [ -n "$TUNNEL_HOSTNAME" ]; then
    # Tunnel nommé : utiliser l'hostname configuré
    TUNNEL_URL="https://$TUNNEL_HOSTNAME"
    echo "Tunnel nommé: $TUNNEL_URL" >> "$LOG_FILE"
else
    # Quick tunnel : extraire l'URL des logs
    for i in {1..20}; do
        TUNNEL_URL=$(grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' "$LOG_FILE" 2>/dev/null | tail -1)
        if [ -n "$TUNNEL_URL" ]; then
            break
        fi
        sleep 1
    done
fi

if [ -n "$TUNNEL_URL" ]; then
    echo "URL: $TUNNEL_URL" >> "$LOG_FILE"
else
    echo "WARN: URL du tunnel non trouvée" >> "$LOG_FILE"
fi

# Enregistrement N8N
if [ -z "$N8N_HOSTNAME" ]; then
    echo "N8N: non configuré (N8N_HOSTNAME manquant)" >> "$LOG_FILE"
elif [ -z "$TUNNEL_URL" ]; then
    echo "N8N: impossible d'enregistrer (URL tunnel manquante)" >> "$LOG_FILE"
else
    ULY_USER_NAME=$(git config user.name 2>/dev/null || id -F 2>/dev/null || echo "$USER")
    SESSION_ID="uly-$(date +%Y-%m-%d)"

    echo "N8N: enregistrement vers $N8N_HOSTNAME..." >> "$LOG_FILE"

    REGISTER_RESULT=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "https://${N8N_HOSTNAME}/webhook/uly-register" \
        -H "Content-Type: application/json" \
        -d "{\"hostname\": \"${TUNNEL_URL}\", \"name\": \"${ULY_USER_NAME}\", \"token\": \"${ULY_API_TOKEN}\", \"session_id\": \"${SESSION_ID}\"}" \
        2>&1)

    HTTP_CODE=$(echo "$REGISTER_RESULT" | grep "HTTP_CODE:" | cut -d: -f2)

    if [ "$HTTP_CODE" = "200" ]; then
        echo "N8N: enregistré avec succès" >> "$LOG_FILE"
    else
        echo "N8N: échec (HTTP $HTTP_CODE)" >> "$LOG_FILE"
        echo "$REGISTER_RESULT" >> "$LOG_FILE"
    fi
fi

echo "started"
exit 0
