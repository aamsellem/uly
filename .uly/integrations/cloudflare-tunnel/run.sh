#!/bin/bash
# Démarrer le serveur ULY API et le tunnel Cloudflare

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ULY API - Démarrage${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Vérifier l'environnement virtuel
if [ ! -d "venv" ]; then
    echo -e "${RED}✗ Environnement virtuel non trouvé${NC}"
    echo "Lancez d'abord : ./.uly/integrations/cloudflare-tunnel/setup.sh"
    exit 1
fi

# Charger les variables d'environnement
if [ -f ".env" ]; then
    source .env
elif [ -f "../../../.env" ]; then
    source ../../../.env
fi

# Vérifier le token API
if [ -z "$ULY_API_TOKEN" ]; then
    echo -e "${RED}✗ ULY_API_TOKEN non défini${NC}"
    echo "Relancez le setup ou ajoutez ULY_API_TOKEN à votre .env"
    exit 1
fi

# Vérifier la clé Anthropic
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo -e "${YELLOW}⚠ ANTHROPIC_API_KEY non définie${NC}"
    echo "L'API ne pourra pas appeler Claude."
fi

# Activer l'environnement virtuel
source venv/bin/activate

# Démarrer le serveur
echo -e "${GREEN}▶ Démarrage du serveur API...${NC}"
echo ""
echo -e "  Token d'authentification : ${YELLOW}$ULY_API_TOKEN${NC}"
echo ""

# Option pour démarrer le tunnel aussi
if command -v cloudflared &> /dev/null && [ -n "$CLOUDFLARE_TUNNEL_NAME" ]; then
    echo -e "${BLUE}Démarrage du tunnel Cloudflare...${NC}"
    cloudflared tunnel run "$CLOUDFLARE_TUNNEL_NAME" &
    TUNNEL_PID=$!
    echo -e "${GREEN}✓ Tunnel démarré (PID: $TUNNEL_PID)${NC}"
    echo ""
fi

# Démarrer le serveur Python
python server.py

# Cleanup si tunnel actif
if [ -n "$TUNNEL_PID" ]; then
    kill $TUNNEL_PID 2>/dev/null || true
fi
