#!/bin/bash
# Script de Configuration Cloudflare Tunnel pour ULY
# Expose ULY via un endpoint HTTPS securise pour N8N et autres automatisations

set -e

# Couleurs pour la sortie
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Pas de Couleur

# Repertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ULY_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Configuration Cloudflare Tunnel${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Expose ULY sur Internet via un tunnel HTTPS securise."
echo "Parfait pour N8N, Make, Zapier, et autres webhooks."
echo ""

# ========================================
# Verifications des prerequis
# ========================================

echo -e "${BLUE}Verification des prerequis...${NC}"
echo ""

# Verifier Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo -e "${GREEN}✓ Python installe (${PYTHON_VERSION})${NC}"
else
    echo -e "${RED}✗ Python 3 non trouve${NC}"
    echo "  Installez Python 3.10+ depuis https://python.org"
    exit 1
fi

# Verifier pip
if command -v pip3 &> /dev/null; then
    echo -e "${GREEN}✓ pip installe${NC}"
else
    echo -e "${RED}✗ pip non trouve${NC}"
    echo "  Installez pip : python3 -m ensurepip"
    exit 1
fi

# Verifier/Installer cloudflared
if command -v cloudflared &> /dev/null; then
    CLOUDFLARED_VERSION=$(cloudflared --version 2>&1 | head -1)
    echo -e "${GREEN}✓ cloudflared installe${NC}"
    echo "  $CLOUDFLARED_VERSION"
else
    echo -e "${YELLOW}! cloudflared non trouve${NC}"
    echo ""
    echo "Installation automatique de cloudflared..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install cloudflare/cloudflare/cloudflared
        else
            echo -e "${RED}✗ Homebrew requis pour installer cloudflared sur macOS${NC}"
            echo "  Installez Homebrew : https://brew.sh"
            echo "  Ou installez cloudflared manuellement : https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            curl -L --output /tmp/cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
            sudo dpkg -i /tmp/cloudflared.deb
            rm /tmp/cloudflared.deb
        elif command -v yum &> /dev/null; then
            curl -L --output /tmp/cloudflared.rpm https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-x86_64.rpm
            sudo yum install -y /tmp/cloudflared.rpm
            rm /tmp/cloudflared.rpm
        else
            echo -e "${RED}✗ Impossible d'installer cloudflared automatiquement${NC}"
            echo "  Installez manuellement : https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation"
            exit 1
        fi
    else
        echo -e "${RED}✗ Systeme non supporte pour l'installation automatique${NC}"
        echo "  Installez cloudflared manuellement : https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation"
        exit 1
    fi

    if command -v cloudflared &> /dev/null; then
        echo -e "${GREEN}✓ cloudflared installe avec succes${NC}"
    else
        echo -e "${RED}✗ Installation de cloudflared echouee${NC}"
        exit 1
    fi
fi

# Verifier cle API Anthropic
if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo -e "${GREEN}✓ ANTHROPIC_API_KEY trouve dans l'environnement${NC}"
elif [ -f "$ULY_ROOT/.env" ] && grep -q "ANTHROPIC_API_KEY" "$ULY_ROOT/.env"; then
    echo -e "${GREEN}✓ ANTHROPIC_API_KEY trouve dans .env${NC}"
else
    echo -e "${YELLOW}! ANTHROPIC_API_KEY non trouve${NC}"
    echo "  Vous devrez le definir avant de lancer le serveur."
    echo "  Obtenez votre cle : https://console.anthropic.com/settings/keys"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Etape 1: Type de Tunnel${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Deux options disponibles :"
echo ""
echo "  1) Tunnel rapide (Quick Tunnel)"
echo "     - Pas besoin de compte Cloudflare"
echo "     - URL temporaire qui change a chaque redemarrage"
echo "     - Parfait pour tester"
echo ""
echo "  2) Tunnel nomme (Named Tunnel)"
echo "     - Necessite un compte Cloudflare (gratuit)"
echo "     - URL permanente et stable"
echo "     - Recommande pour la production"
echo ""
echo -e "${YELLOW}Choix [1]:${NC}"
read -r TUNNEL_TYPE
TUNNEL_TYPE=${TUNNEL_TYPE:-1}

TUNNEL_NAME=""
USE_NAMED_TUNNEL=false

if [[ "$TUNNEL_TYPE" == "2" ]]; then
    USE_NAMED_TUNNEL=true

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Connexion a Cloudflare${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Vous allez etre redirige vers Cloudflare pour vous connecter."
    echo ""
    echo -e "${YELLOW}Appuyez sur Entree pour continuer...${NC}"
    read -r

    cloudflared tunnel login

    echo ""
    echo -e "${GREEN}✓ Connexion reussie${NC}"

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Creation du Tunnel${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Nom pour votre tunnel (ex: uly-tunnel, mon-assistant) :"
    echo ""
    echo -e "${YELLOW}Nom [uly-tunnel]:${NC}"
    read -r TUNNEL_NAME
    TUNNEL_NAME=${TUNNEL_NAME:-uly-tunnel}

    # Supprimer le tunnel existant si present
    cloudflared tunnel delete "$TUNNEL_NAME" 2>/dev/null || true

    # Creer le nouveau tunnel
    cloudflared tunnel create "$TUNNEL_NAME"

    echo ""
    echo -e "${GREEN}✓ Tunnel '$TUNNEL_NAME' cree${NC}"

    # Obtenir l'ID du tunnel
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')

    # Creer la configuration du tunnel
    cat > "$SCRIPT_DIR/config.yml" << EOF
tunnel: $TUNNEL_ID
credentials-file: $HOME/.cloudflared/$TUNNEL_ID.json

ingress:
  - service: http://localhost:8787
EOF

    echo -e "${GREEN}✓ Configuration du tunnel creee${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Etape 2: Token d'Authentification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Un token securise protege votre API contre les acces non autorises."
echo ""

# Generer un token aleatoire
GENERATED_TOKEN=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

echo "Token genere automatiquement : "
echo -e "${GREEN}$GENERATED_TOKEN${NC}"
echo ""
echo "Voulez-vous utiliser ce token ou en definir un personnalise ?"
echo "  1) Utiliser le token genere"
echo "  2) Definir mon propre token"
echo ""
echo -e "${YELLOW}Choix [1]:${NC}"
read -r TOKEN_CHOICE
TOKEN_CHOICE=${TOKEN_CHOICE:-1}

if [[ "$TOKEN_CHOICE" == "2" ]]; then
    echo ""
    echo -e "${YELLOW}Entrez votre token (min 16 caracteres):${NC}"
    read -rs API_TOKEN
    echo ""

    if [ ${#API_TOKEN} -lt 16 ]; then
        echo -e "${RED}✗ Token trop court (minimum 16 caracteres)${NC}"
        echo "  Utilisation du token genere a la place."
        API_TOKEN="$GENERATED_TOKEN"
    fi
else
    API_TOKEN="$GENERATED_TOKEN"
fi

echo -e "${GREEN}✓ Token configure${NC}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Etape 3: Installation des Dependances${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Creer l'environnement virtuel
if [ ! -d "$SCRIPT_DIR/venv" ]; then
    echo "Creation de l'environnement virtuel..."
    python3 -m venv "$SCRIPT_DIR/venv"
fi

echo "Activation de l'environnement virtuel..."
source "$SCRIPT_DIR/venv/bin/activate"

echo "Installation des dependances..."
pip install -q --upgrade pip
pip install -q fastapi uvicorn anthropic python-dotenv aiofiles

echo -e "${GREEN}✓ Dependances installees${NC}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Etape 4: Sauvegarde de la Configuration${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Creer le fichier .env
cat > "$SCRIPT_DIR/.env" << EOF
# Configuration Cloudflare Tunnel pour ULY
# Genere par setup.sh le $(date)

# Token d'authentification API (GARDEZ SECRET)
ULY_API_TOKEN=$API_TOKEN

# Type de tunnel
USE_NAMED_TUNNEL=$USE_NAMED_TUNNEL
TUNNEL_NAME=$TUNNEL_NAME

# Port du serveur local
SERVER_PORT=8787

# Chemin vers l'espace de travail ULY
ULY_WORKSPACE=$ULY_ROOT
EOF

echo -e "${GREEN}✓ Configuration sauvegardee dans .env${NC}"

# Creer le script run.sh
cat > "$SCRIPT_DIR/run.sh" << 'RUNSCRIPT'
#!/bin/bash
# Demarre le serveur ULY et le tunnel Cloudflare

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Charger la configuration
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

# Charger aussi .env du projet principal pour ANTHROPIC_API_KEY
ULY_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [ -f "$ULY_ROOT/.env" ]; then
    export $(grep -v '^#' "$ULY_ROOT/.env" | xargs)
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Demarrage ULY API + Tunnel${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Verifier ANTHROPIC_API_KEY
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo -e "${RED}✗ ANTHROPIC_API_KEY non defini${NC}"
    echo "  Ajoutez-le a votre fichier .env"
    exit 1
fi

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

echo -e "${GREEN}✓ Serveur API demarre (PID: $SERVER_PID)${NC}"

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
    # Quick tunnel
    cloudflared tunnel --url http://localhost:${SERVER_PORT:-8787} 2>&1 | tee /tmp/cloudflared.log &
    TUNNEL_PID=$!

    # Attendre et extraire l'URL
    sleep 5
    TUNNEL_URL=$(grep -o 'https://[^ ]*\.trycloudflare\.com' /tmp/cloudflared.log | head -1)
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ULY API en Ligne !${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "URL publique : ${BLUE}${TUNNEL_URL}${NC}"
echo ""
echo "Votre token d'authentification :"
echo -e "${YELLOW}$ULY_API_TOKEN${NC}"
echo ""
echo "Exemple de requete :"
echo -e "${BLUE}curl -X POST ${TUNNEL_URL}/ask \\${NC}"
echo -e "${BLUE}  -H \"Authorization: Bearer \$ULY_API_TOKEN\" \\${NC}"
echo -e "${BLUE}  -H \"Content-Type: application/json\" \\${NC}"
echo -e "${BLUE}  -d '{\"message\": \"Quel est mon etat actuel?\"}'${NC}"
echo ""
echo -e "${YELLOW}Appuyez sur Ctrl+C pour arreter${NC}"
echo ""

# Attendre
wait
RUNSCRIPT

chmod +x "$SCRIPT_DIR/run.sh"
echo -e "${GREEN}✓ Script de demarrage cree${NC}"

# Ajouter .env au .gitignore
if [ ! -f "$SCRIPT_DIR/.gitignore" ]; then
    cat > "$SCRIPT_DIR/.gitignore" << EOF
.env
venv/
__pycache__/
*.pyc
config.yml
*.log
EOF
    echo -e "${GREEN}✓ .gitignore cree${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Configuration Terminee !${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Pour demarrer le service :"
echo ""
echo -e "  ${YELLOW}./.uly/integrations/cloudflare-tunnel/run.sh${NC}"
echo ""
echo "Votre token d'authentification :"
echo -e "  ${GREEN}$API_TOKEN${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: Gardez ce token secret !${NC}"
echo "Il est sauvegarde dans .uly/integrations/cloudflare-tunnel/.env"
echo ""
echo "Essayez ces commandes une fois le service demarre :"
echo ""
echo -e "  ${YELLOW}curl http://localhost:8787/health${NC}"
echo -e "  ${YELLOW}curl -X POST http://localhost:8787/ask -H \"Authorization: Bearer \$TOKEN\" -H \"Content-Type: application/json\" -d '{\"message\": \"Bonjour !\"}'${NC}"
echo ""
echo -e "${GREEN}Vous etes pret !${NC}"
echo ""
