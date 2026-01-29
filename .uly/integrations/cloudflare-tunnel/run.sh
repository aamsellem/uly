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

# Paramètres
N8N_HOSTNAME="${1:-$N8N_HOSTNAME}"

# Récupérer le nom de l'utilisateur automatiquement
if [ -z "$ULY_USER_NAME" ]; then
    ULY_USER_NAME=$(git config user.name 2>/dev/null || id -F 2>/dev/null || echo "$USER")
fi

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

    # Récupérer le hostname Cloudflare
    sleep 3  # Attendre que le tunnel soit établi
    CLOUDFLARE_HOSTNAME=$(cloudflared tunnel info "$CLOUDFLARE_TUNNEL_NAME" 2>/dev/null | grep -oE '[a-zA-Z0-9-]+\.trycloudflare\.com' | head -1)

    # Si hostname non trouvé via info, essayer avec la config DNS
    if [ -z "$CLOUDFLARE_HOSTNAME" ]; then
        CLOUDFLARE_HOSTNAME=$(cloudflared tunnel route dns "$CLOUDFLARE_TUNNEL_NAME" 2>/dev/null | grep -oE '[a-zA-Z0-9.-]+\.[a-zA-Z]+' | head -1)
    fi

    # Enregistrer auprès de N8N si hostname fourni
    if [ -n "$N8N_HOSTNAME" ] && [ -n "$CLOUDFLARE_HOSTNAME" ]; then
        echo -e "${BLUE}Enregistrement auprès de N8N...${NC}"

        REGISTER_RESPONSE=$(curl -s -X POST "https://${N8N_HOSTNAME}/webhook/uly-register" \
            -H "Content-Type: application/json" \
            -d "{\"hostname\": \"${CLOUDFLARE_HOSTNAME}\", \"name\": \"${ULY_USER_NAME}\", \"token\": \"${ULY_API_TOKEN}\"}" \
            2>/dev/null)

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Enregistré auprès de N8N${NC}"
            echo -e "  Hostname: ${YELLOW}${CLOUDFLARE_HOSTNAME}${NC}"
        else
            echo -e "${YELLOW}⚠ Échec de l'enregistrement N8N${NC}"
        fi
    elif [ -n "$N8N_HOSTNAME" ] && [ -z "$CLOUDFLARE_HOSTNAME" ]; then
        echo -e "${YELLOW}⚠ Hostname Cloudflare non trouvé, enregistrement N8N ignoré${NC}"
    fi
    echo ""
fi

# Démarrer le serveur Python
python server.py

# Cleanup si tunnel actif
if [ -n "$TUNNEL_PID" ]; then
    kill $TUNNEL_PID 2>/dev/null || true
fi
