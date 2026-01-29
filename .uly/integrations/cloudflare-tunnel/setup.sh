#!/bin/bash
# Script de Configuration Cloudflare Tunnel pour ULY
# Expose ULY via un endpoint HTTPS securise pour N8N et autres automatisations

set -e

# Couleurs pour la sortie
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # Pas de Couleur

# Repertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ULY_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

clear
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}       ${BOLD}Configuration Cloudflare Tunnel pour ULY${NC}           ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Ce script va configurer un tunnel securise pour acceder a ULY"
echo "depuis Internet (N8N, Make, Zapier, webhooks, etc.)"
echo ""
echo -e "${DIM}Temps estime : 2-5 minutes${NC}"
echo ""
echo -e "${YELLOW}Appuyez sur Entree pour commencer...${NC}"
read -r

# ========================================
# ETAPE 1: Type de tunnel
# ========================================

clear
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${BOLD}Etape 1/4 : Choix du Type de Tunnel${NC}                      ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Qu'est-ce qu'un tunnel Cloudflare ?${NC}"
echo ""
echo "  Un tunnel cree un lien securise entre votre ordinateur et Internet."
echo "  Pas besoin d'ouvrir de ports sur votre routeur/firewall."
echo "  Tout le trafic passe par HTTPS (chiffre)."
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}Option 1 : Tunnel Rapide (Quick Tunnel)${NC}"
echo ""
echo -e "  ${GREEN}+${NC} Pas besoin de compte Cloudflare"
echo -e "  ${GREEN}+${NC} Pret en 30 secondes"
echo -e "  ${GREEN}+${NC} Parfait pour tester"
echo ""
echo -e "  ${RED}-${NC} URL temporaire (change a chaque redemarrage)"
echo -e "  ${RED}-${NC} Exemple : https://random-words-here.trycloudflare.com"
echo ""
echo -e "  ${DIM}Recommande si : Vous voulez juste tester ou usage occasionnel${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}Option 2 : Tunnel Nomme (Named Tunnel)${NC}"
echo ""
echo -e "  ${GREEN}+${NC} URL permanente et stable"
echo -e "  ${GREEN}+${NC} Meme URL a chaque redemarrage"
echo -e "  ${GREEN}+${NC} Peut etre connecte a votre propre domaine"
echo ""
echo -e "  ${RED}-${NC} Necessite un compte Cloudflare (gratuit)"
echo -e "  ${RED}-${NC} Configuration initiale plus longue"
echo ""
echo -e "  ${DIM}Recommande si : Usage en production, workflows N8N permanents${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Quel type de tunnel voulez-vous ?"
echo ""
echo -e "  ${BOLD}1)${NC} Tunnel Rapide ${DIM}(recommande pour debuter)${NC}"
echo -e "  ${BOLD}2)${NC} Tunnel Nomme ${DIM}(recommande pour la production)${NC}"
echo ""
echo -e "${YELLOW}Votre choix [1]:${NC} "
read -r TUNNEL_TYPE
TUNNEL_TYPE=${TUNNEL_TYPE:-1}

TUNNEL_NAME=""
USE_NAMED_TUNNEL=false

if [[ "$TUNNEL_TYPE" == "2" ]]; then
    USE_NAMED_TUNNEL=true

    echo ""
    echo -e "${CYAN}━━━ Configuration du Tunnel Nomme ━━━${NC}"
    echo ""
    echo -e "${BOLD}Prerequis :${NC} Compte Cloudflare (gratuit)"
    echo ""
    echo -e "${YELLOW}Vous n'avez pas encore de compte ?${NC}"
    echo ""
    echo -e "  1. Allez sur ${BLUE}https://dash.cloudflare.com/sign-up${NC}"
    echo "  2. Creez un compte avec votre email"
    echo "  3. Pas besoin d'ajouter de domaine pour le tunnel"
    echo "  4. Revenez ici une fois connecte"
    echo ""
    echo -e "${YELLOW}Appuyez sur Entree quand vous avez un compte Cloudflare...${NC}"
    read -r

    echo ""
    echo -e "${CYAN}Nom de votre tunnel :${NC}"
    echo ""
    echo "  Ce nom identifie votre tunnel dans Cloudflare."
    echo "  Utilisez quelque chose de reconnaissable."
    echo ""
    echo "  Exemples : uly-maison, uly-bureau, mon-assistant"
    echo ""
    echo -e "${YELLOW}Nom du tunnel [uly-tunnel]:${NC} "
    read -r TUNNEL_NAME
    TUNNEL_NAME=${TUNNEL_NAME:-uly-tunnel}

    echo ""
    echo -e "${GREEN}✓ Tunnel nomme : $TUNNEL_NAME${NC}"
fi

# ========================================
# ETAPE 2: Token d'authentification
# ========================================

clear
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${BOLD}Etape 2/4 : Token d'Authentification${NC}                     ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Pourquoi un token ?${NC}"
echo ""
echo "  Le token est comme un mot de passe pour votre API."
echo "  Sans lui, n'importe qui avec l'URL pourrait controler ULY."
echo ""
echo -e "  ${BOLD}Chaque requete doit inclure :${NC}"
echo "  Authorization: Bearer VOTRE_TOKEN"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Generer un token aleatoire
if command -v python3 &> /dev/null; then
    GENERATED_TOKEN=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
else
    GENERATED_TOKEN=$(cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 43 | head -n 1)
fi

echo -e "${BOLD}Token genere automatiquement :${NC}"
echo ""
echo -e "  ${GREEN}$GENERATED_TOKEN${NC}"
echo ""
echo -e "${DIM}(Ce token est cryptographiquement securise)${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Que voulez-vous faire ?"
echo ""
echo -e "  ${BOLD}1)${NC} Utiliser ce token ${DIM}(recommande)${NC}"
echo -e "  ${BOLD}2)${NC} Entrer mon propre token"
echo ""
echo -e "${YELLOW}Votre choix [1]:${NC} "
read -r TOKEN_CHOICE
TOKEN_CHOICE=${TOKEN_CHOICE:-1}

if [[ "$TOKEN_CHOICE" == "2" ]]; then
    echo ""
    echo -e "${CYAN}Votre token personnalise :${NC}"
    echo ""
    echo "  - Minimum 16 caracteres"
    echo "  - Melangez lettres, chiffres, symboles"
    echo "  - Ne reutilisez pas un mot de passe existant"
    echo ""
    echo -e "${YELLOW}Entrez votre token (les caracteres sont masques) :${NC} "
    read -rs API_TOKEN
    echo ""

    if [ ${#API_TOKEN} -lt 16 ]; then
        echo -e "${RED}! Token trop court (${#API_TOKEN} caracteres, minimum 16)${NC}"
        echo "  Utilisation du token genere a la place."
        API_TOKEN="$GENERATED_TOKEN"
    else
        echo -e "${GREEN}✓ Token personnalise accepte${NC}"
    fi
else
    API_TOKEN="$GENERATED_TOKEN"
    echo -e "${GREEN}✓ Token genere utilise${NC}"
fi

# ========================================
# ETAPE 3: IP Whitelist (optionnel)
# ========================================

clear
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${BOLD}Etape 3/4 : Restriction par IP (Optionnel)${NC}               ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Qu'est-ce que l'IP Whitelist ?${NC}"
echo ""
echo "  En plus du token, vous pouvez limiter l'acces a certaines IPs."
echo "  Seules ces IPs pourront appeler votre API."
echo ""
echo -e "  ${BOLD}Sans whitelist :${NC} Tout le monde avec le token peut acceder"
echo -e "  ${BOLD}Avec whitelist :${NC} Seules les IPs listees + token peuvent acceder"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}Comment trouver l'IP de votre serveur N8N ?${NC}"
echo ""
echo -e "  ${BOLD}Si N8N est sur un VPS/serveur :${NC}"
echo -e "    Connectez-vous en SSH et tapez : ${BLUE}curl ifconfig.me${NC}"
echo ""
echo -e "  ${BOLD}Si N8N est chez vous :${NC}"
echo -e "    Allez sur ${BLUE}https://whatismyip.com${NC} depuis ce PC"
echo ""
echo -e "  ${BOLD}Si N8N est sur n8n.cloud :${NC}"
echo "    Contactez le support n8n pour connaitre leurs IPs"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Voulez-vous configurer une IP Whitelist ?"
echo ""
echo -e "  ${BOLD}1)${NC} Non, autoriser toutes les IPs ${DIM}(le token suffit)${NC}"
echo -e "  ${BOLD}2)${NC} Oui, limiter a certaines IPs ${DIM}(securite maximale)${NC}"
echo ""
echo -e "${YELLOW}Votre choix [1]:${NC} "
read -r WHITELIST_CHOICE
WHITELIST_CHOICE=${WHITELIST_CHOICE:-1}

IP_WHITELIST=""

if [[ "$WHITELIST_CHOICE" == "2" ]]; then
    echo ""
    echo -e "${CYAN}Entrez les IPs autorisees :${NC}"
    echo ""
    echo "  Format : IP1,IP2,IP3 (separees par des virgules)"
    echo "  Exemple : 203.0.113.50,198.51.100.25"
    echo ""
    echo -e "${YELLOW}IPs autorisees :${NC} "
    read -r IP_WHITELIST

    if [[ -n "$IP_WHITELIST" ]]; then
        echo -e "${GREEN}✓ Whitelist configuree : $IP_WHITELIST${NC}"
    else
        echo -e "${YELLOW}! Aucune IP entree, whitelist desactivee${NC}"
    fi
else
    echo -e "${GREEN}✓ Whitelist desactivee (toutes IPs autorisees avec token)${NC}"
fi

# ========================================
# Resume avant installation
# ========================================

clear
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${BOLD}Etape 4/4 : Resume et Installation${NC}                       ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Recapitulatif de vos choix :${NC}"
echo ""
if [[ "$USE_NAMED_TUNNEL" == "true" ]]; then
    echo -e "  Type de tunnel   : ${GREEN}Tunnel Nomme ($TUNNEL_NAME)${NC}"
    echo -e "                     ${DIM}URL permanente${NC}"
else
    echo -e "  Type de tunnel   : ${GREEN}Tunnel Rapide${NC}"
    echo -e "                     ${DIM}URL temporaire (change a chaque redemarrage)${NC}"
fi
echo ""
echo -e "  Token            : ${GREEN}${API_TOKEN:0:20}...${NC}"
echo -e "                     ${DIM}${#API_TOKEN} caracteres${NC}"
echo ""
if [[ -n "$IP_WHITELIST" ]]; then
    echo -e "  IP Whitelist     : ${GREEN}$IP_WHITELIST${NC}"
else
    echo -e "  IP Whitelist     : ${YELLOW}Desactivee${NC}"
    echo -e "                     ${DIM}Toutes les IPs autorisees (avec token)${NC}"
fi
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}L'installation va :${NC}"
echo ""
echo -e "  1. Verifier les prerequis (Python, Claude Code, cloudflared)"
echo -e "  2. Installer cloudflared si necessaire"
if [[ "$USE_NAMED_TUNNEL" == "true" ]]; then
    echo "  3. Vous connecter a Cloudflare (navigateur)"
    echo "  4. Creer le tunnel '$TUNNEL_NAME'"
fi
echo -e "  5. Configurer le serveur API"
echo ""
echo -e "${YELLOW}Appuyez sur Entree pour lancer l'installation, ou Ctrl+C pour annuler...${NC}"
read -r

# ========================================
# Installation
# ========================================

echo ""
echo -e "${BLUE}━━━ Verification des Prerequis ━━━${NC}"
echo ""

# Verifier Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo -e "${GREEN}✓${NC} Python installe (${PYTHON_VERSION})"
else
    echo -e "${RED}✗${NC} Python 3 non trouve"
    echo ""
    echo -e "  ${BOLD}Comment installer Python :${NC}"
    echo "    macOS   : brew install python3"
    echo "    Ubuntu  : sudo apt install python3"
    echo "    Windows : https://python.org/downloads"
    exit 1
fi

# Verifier pip
if command -v pip3 &> /dev/null; then
    echo -e "${GREEN}✓${NC} pip installe"
else
    echo -e "${RED}✗${NC} pip non trouve"
    echo "  Installez pip : python3 -m ensurepip"
    exit 1
fi

# Verifier Claude Code
if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓${NC} Claude Code installe"
else
    echo -e "${RED}✗${NC} Claude Code non trouve"
    echo ""
    echo -e "  ${BOLD}Comment installer Claude Code :${NC}"
    echo "    npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# Verifier/Installer cloudflared
if command -v cloudflared &> /dev/null; then
    CLOUDFLARED_VERSION=$(cloudflared --version 2>&1 | head -1)
    echo -e "${GREEN}✓${NC} cloudflared installe"
    echo "    $CLOUDFLARED_VERSION"
else
    echo -e "${YELLOW}!${NC} cloudflared non trouve - installation en cours..."
    echo ""

    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            echo "  Installation via Homebrew..."
            brew install cloudflare/cloudflare/cloudflared
        else
            echo -e "${RED}✗${NC} Homebrew requis pour installer cloudflared sur macOS"
            echo ""
            echo -e "  ${BOLD}Installez Homebrew :${NC}"
            echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            echo ""
            echo -e "  ${BOLD}Ou installez cloudflared manuellement :${NC}"
            echo "    https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            echo "  Telechargement du paquet Debian..."
            curl -L --output /tmp/cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
            sudo dpkg -i /tmp/cloudflared.deb
            rm /tmp/cloudflared.deb
        elif command -v yum &> /dev/null; then
            echo "  Telechargement du paquet RPM..."
            curl -L --output /tmp/cloudflared.rpm https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-x86_64.rpm
            sudo yum install -y /tmp/cloudflared.rpm
            rm /tmp/cloudflared.rpm
        else
            echo -e "${RED}✗${NC} Impossible d'installer cloudflared automatiquement"
            echo "  Installez manuellement : https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation"
            exit 1
        fi
    else
        echo -e "${RED}✗${NC} Systeme non supporte pour l'installation automatique"
        echo "  Installez manuellement : https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation"
        exit 1
    fi

    if command -v cloudflared &> /dev/null; then
        echo -e "${GREEN}✓${NC} cloudflared installe avec succes"
    else
        echo -e "${RED}✗${NC} Installation de cloudflared echouee"
        exit 1
    fi
fi

# ========================================
# Configuration Cloudflare (si tunnel nomme)
# ========================================

if [[ "$USE_NAMED_TUNNEL" == "true" ]]; then
    echo ""
    echo -e "${BLUE}━━━ Connexion a Cloudflare ━━━${NC}"
    echo ""
    echo "Un navigateur va s'ouvrir pour vous connecter a Cloudflare."
    echo ""
    echo -e "${CYAN}Instructions :${NC}"
    echo "  1. Connectez-vous avec votre compte Cloudflare"
    echo "  2. Autorisez cloudflared"
    echo "  3. Revenez ici une fois termine"
    echo ""
    echo -e "${YELLOW}Appuyez sur Entree pour ouvrir le navigateur...${NC}"
    read -r

    cloudflared tunnel login

    echo ""
    echo -e "${GREEN}✓${NC} Connexion reussie"

    echo ""
    echo -e "${BLUE}━━━ Creation du Tunnel ━━━${NC}"
    echo ""

    # Supprimer le tunnel existant si present
    echo "  Verification si le tunnel existe deja..."
    cloudflared tunnel delete "$TUNNEL_NAME" 2>/dev/null || true

    # Creer le nouveau tunnel
    echo "  Creation du tunnel '$TUNNEL_NAME'..."
    cloudflared tunnel create "$TUNNEL_NAME"

    echo ""
    echo -e "${GREEN}✓${NC} Tunnel '$TUNNEL_NAME' cree"

    # Obtenir l'ID du tunnel
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')

    # Creer la configuration du tunnel
    cat > "$SCRIPT_DIR/config.yml" << EOF
tunnel: $TUNNEL_ID
credentials-file: $HOME/.cloudflared/$TUNNEL_ID.json

ingress:
  - service: http://localhost:8787
EOF

    echo -e "${GREEN}✓${NC} Configuration du tunnel creee"
fi

# ========================================
# Installation des dependances Python
# ========================================

echo ""
echo -e "${BLUE}━━━ Installation des Dependances Python ━━━${NC}"
echo ""

# Creer l'environnement virtuel
if [ ! -d "$SCRIPT_DIR/venv" ]; then
    echo "  Creation de l'environnement virtuel..."
    python3 -m venv "$SCRIPT_DIR/venv"
fi

echo "  Activation de l'environnement virtuel..."
source "$SCRIPT_DIR/venv/bin/activate"

echo "  Installation des packages..."
pip install -q --upgrade pip
pip install -q fastapi uvicorn python-dotenv aiofiles

echo -e "${GREEN}✓${NC} Dependances installees"

# ========================================
# Sauvegarde de la configuration
# ========================================

echo ""
echo -e "${BLUE}━━━ Sauvegarde de la Configuration ━━━${NC}"
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

# IP Whitelist (optionnel, separees par des virgules)
# Laissez vide pour autoriser toutes les IPs
ULY_IP_WHITELIST=$IP_WHITELIST
EOF

echo -e "${GREEN}✓${NC} Configuration sauvegardee dans .env"

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
DIM='\033[2m'
NC='\033[0m'

# Charger la configuration
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

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
echo "  Exemple de requete :"
echo ""
echo -e "  ${BLUE}curl -X POST ${TUNNEL_URL}/ask \\${NC}"
echo -e "  ${BLUE}  -H \"Authorization: Bearer \$ULY_API_TOKEN\" \\${NC}"
echo -e "  ${BLUE}  -H \"Content-Type: application/json\" \\${NC}"
echo -e "  ${BLUE}  -d '{\"message\": \"Bonjour !\"}'${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${YELLOW}Appuyez sur Ctrl+C pour arreter${NC}"
echo ""

# Attendre
wait
RUNSCRIPT

chmod +x "$SCRIPT_DIR/run.sh"
echo -e "${GREEN}✓${NC} Script de demarrage cree"

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
    echo -e "${GREEN}✓${NC} .gitignore cree"
fi

# ========================================
# Message final
# ========================================

clear
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}           ${BOLD}Configuration Terminee avec Succes !${NC}            ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Votre token d'authentification :${NC}"
echo ""
echo -e "  ${GREEN}$API_TOKEN${NC}"
echo ""
echo -e "  ${RED}IMPORTANT : Gardez ce token secret !${NC}"
echo "  Il est sauvegarde dans : .uly/integrations/cloudflare-tunnel/.env"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}Pour demarrer ULY API :${NC}"
echo ""
echo -e "  ${BOLD}./.uly/integrations/cloudflare-tunnel/run.sh${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}Test local (une fois le service demarre) :${NC}"
echo ""
echo -e "  ${BLUE}curl http://localhost:8787/health${NC}"
echo ""
echo -e "${CYAN}Test avec authentification :${NC}"
echo ""
echo -e "  ${BLUE}curl -X POST http://localhost:8787/ask \\${NC}"
echo -e "  ${BLUE}  -H \"Authorization: Bearer $API_TOKEN\" \\${NC}"
echo -e "  ${BLUE}  -H \"Content-Type: application/json\" \\${NC}"
echo -e "  ${BLUE}  -d '{\"message\": \"Bonjour !\"}'${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}Configuration N8N :${NC}"
echo ""
echo -e "  1. Ajoutez un noeud HTTP Request"
echo -e "  2. Methode : POST"
echo -e "  3. URL : [votre URL tunnel]/ask"
echo -e "  4. Authentication : Header Auth"
echo "     - Header Name  : Authorization"
echo "     - Header Value : Bearer $API_TOKEN"
echo -e "  5. Body : { \"message\": \"{{ \$json.input }}\" }"
echo ""
echo -e "${GREEN}Vous etes pret !${NC}"
echo ""
