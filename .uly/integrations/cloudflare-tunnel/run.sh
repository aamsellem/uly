#!/bin/bash
# Demarre le serveur ULY et le tunnel Cloudflare

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

# Charger la configuration
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

# Parametre optionnel : N8N_HOSTNAME
N8N_HOSTNAME="${1:-$N8N_HOSTNAME}"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}     ${GREEN}Demarrage ULY API + Tunnel${NC}        ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Verifier que Claude Code est disponible
if ! command -v claude &> /dev/null; then
    echo -e "${RED}✗ Claude Code non disponible${NC}"
    echo "  Installez-le avec : npm install -g @anthropic-ai/claude-code"
    exit 1
fi

echo -e "${GREEN}✓${NC} Claude Code disponible"

# Activer l'environnement virtuel
source "$SCRIPT_DIR/venv/bin/activate"

# Fonction de nettoyage
cleanup() {
    echo ""
    echo -e "${YELLOW}Arret des services...${NC}"
    kill $SERVER_PID 2>/dev/null
    kill $TUNNEL_PID 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM

# Demarrer le serveur API
echo -e "${BLUE}Demarrage du serveur API sur le port ${SERVER_PORT:-8787}...${NC}"
cd "$SCRIPT_DIR"
python server.py &
SERVER_PID=$!

# Attendre que le serveur demarre
sleep 2

# Verifier que le serveur est demarre
if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo -e "${RED}✗ Le serveur API n'a pas demarre${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Serveur API demarre (PID: $SERVER_PID)"

# Demarrer le tunnel
echo ""
echo -e "${BLUE}Demarrage du tunnel Cloudflare...${NC}"

if [ "$USE_NAMED_TUNNEL" = "true" ]; then
    # Tunnel nomme
    cloudflared tunnel --config "$SCRIPT_DIR/config.yml" run &
    TUNNEL_PID=$!

    sleep 3

    # Afficher l'URL du tunnel
    TUNNEL_URL=$(cloudflared tunnel info "$TUNNEL_NAME" 2>/dev/null | grep -o 'https://[^ ]*' | head -1)
    if [ -z "$TUNNEL_URL" ]; then
        TUNNEL_URL="https://$TUNNEL_NAME.cfargotunnel.com"
    fi
else
    # Quick tunnel - rediriger stdout ET stderr vers le fichier log
    cloudflared tunnel --url http://localhost:${SERVER_PORT:-8787} > /tmp/cloudflared.log 2>&1 &
    TUNNEL_PID=$!

    # Attendre et extraire l'URL (avec retry car cloudflared prend du temps)
    echo -e "  ${DIM}Attente de l'URL du tunnel...${NC}"
    TUNNEL_URL=""
    for i in {1..30}; do
        TUNNEL_URL=$(grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' /tmp/cloudflared.log 2>/dev/null | head -1)
        if [ -n "$TUNNEL_URL" ]; then
            break
        fi
        sleep 1
        echo -ne "\r  ${DIM}Attente de l'URL du tunnel... ${i}s${NC}  "
    done
    echo ""

    if [ -z "$TUNNEL_URL" ]; then
        echo -e "${YELLOW}! URL non detectee automatiquement${NC}"
        echo "  Regardez la sortie cloudflared ci-dessous pour trouver l'URL :"
        echo ""
        cat /tmp/cloudflared.log | grep -i "https://" | head -5
        echo ""
        TUNNEL_URL="[voir ci-dessus]"
    fi
fi

# Enregistrement N8N si configure
if [ -n "$N8N_HOSTNAME" ] && [ -n "$TUNNEL_URL" ] && [ "$TUNNEL_URL" != "[voir ci-dessus]" ]; then
    echo ""
    echo -e "${BLUE}Enregistrement aupres de N8N...${NC}"

    # Auto-detecter le nom utilisateur
    ULY_USER_NAME=$(git config user.name 2>/dev/null || id -F 2>/dev/null || echo "$USER")

    # Session quotidienne (uly-YYYY-MM-DD)
    SESSION_ID="uly-$(date +%Y-%m-%d)"

    REGISTER_RESPONSE=$(curl -s -X POST "https://${N8N_HOSTNAME}/webhook/uly-register" \
        -H "Content-Type: application/json" \
        -d "{\"hostname\": \"${TUNNEL_URL}\", \"name\": \"${ULY_USER_NAME}\", \"token\": \"${ULY_API_TOKEN}\", \"session_id\": \"${SESSION_ID}\"}" \
        2>/dev/null)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Enregistre aupres de N8N"
    else
        echo -e "${YELLOW}! Echec de l'enregistrement N8N${NC}"
    fi
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}              ${GREEN}ULY API en Ligne !${NC}                          ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BLUE}URL publique :${NC} ${TUNNEL_URL}"
echo ""
echo -e "  ${BLUE}Token :${NC} $ULY_API_TOKEN"
echo ""
if [ -n "$ULY_IP_WHITELIST" ]; then
    echo -e "  ${BLUE}IP Whitelist :${NC} $ULY_IP_WHITELIST"
    echo ""
fi
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}Endpoints disponibles :${NC}"
echo ""
echo -e "  POST ${TUNNEL_URL}${GREEN}/ask${NC}        - Poser une question"
echo -e "  POST ${TUNNEL_URL}${GREEN}/command/uly${NC} - Lancer /uly"
echo -e "  POST ${TUNNEL_URL}${GREEN}/raw${NC}        - Commande brute"
echo -e "  GET  ${TUNNEL_URL}${GREEN}/health${NC}     - Verifier le service"
echo ""
echo -e "  ${BOLD}Test rapide :${NC}"
echo ""
echo    "  curl -X POST ${TUNNEL_URL}/ask \\"
echo    "    -H \"Authorization: Bearer \$ULY_API_TOKEN\" \\"
echo    "    -H \"Content-Type: application/json\" \\"
echo    "    -d '{\"message\": \"Bonjour !\"}'"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${YELLOW}Appuyez sur Ctrl+C pour arreter${NC}"
echo ""

# Attendre
wait
