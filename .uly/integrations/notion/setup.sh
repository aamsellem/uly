#!/bin/bash
# Notion MCP Setup Script
# Connectez ULY à votre espace de travail Notion

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Notion MCP Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check Claude Code
if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Claude Code installé${NC}"
else
    echo -e "${RED}✗ Claude Code non trouvé${NC}"
    echo "Installer avec : npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# Check Node.js
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓ Node.js installé${NC}"
else
    echo -e "${RED}✗ Node.js non trouvé${NC}"
    echo "Installez Node.js d'abord : https://nodejs.org"
    exit 1
fi

# Scope selection
echo ""
echo "Où cette intégration doit-elle être disponible ?"
echo "  1) Tous les projets (portée utilisateur)"
echo "  2) Ce projet uniquement (portée projet)"
echo ""
echo -e "${YELLOW}Choix [1]:${NC}"
read -r SCOPE_CHOICE
SCOPE_CHOICE=${SCOPE_CHOICE:-1}

if [[ "$SCOPE_CHOICE" == "1" ]]; then
    SCOPE_FLAG="-s user"
else
    SCOPE_FLAG=""
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Étape 1: Créer une Intégration Notion${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Vous allez créer une intégration interne Notion pour obtenir un token."
echo ""
echo "1. Allez sur : https://www.notion.so/profile/integrations"
echo "2. Cliquez sur 'Nouvelle intégration' ou 'New integration'"
echo "3. Donnez-lui un nom (ex: 'ULY')"
echo "4. Sélectionnez votre espace de travail"
echo "5. Cliquez sur 'Soumettre' ou 'Submit'"
echo ""
echo -e "${YELLOW}Appuyez sur Entrée quand vous avez créé l'intégration...${NC}"
read -r

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Étape 2: Configurer les Permissions${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Dans les paramètres de votre intégration :"
echo ""
echo "1. Allez dans l'onglet 'Capabilities' ou 'Fonctionnalités'"
echo "2. Assurez-vous que ces options sont cochées :"
echo ""
echo -e "   ${YELLOW}✓ Read content${NC}        - Lire le contenu des pages"
echo -e "   ${YELLOW}✓ Update content${NC}      - Modifier le contenu"
echo -e "   ${YELLOW}✓ Insert content${NC}      - Créer du nouveau contenu"
echo -e "   ${YELLOW}✓ Read user information${NC} - (optionnel) Voir les infos utilisateur"
echo ""
echo "3. Cliquez sur 'Enregistrer' si vous avez fait des modifications"
echo ""
echo -e "${YELLOW}Appuyez sur Entrée quand c'est fait...${NC}"
read -r

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Étape 3: Copier Votre Token${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Toujours dans les paramètres de votre intégration :"
echo ""
echo "1. Allez dans l'onglet 'Secrets' ou restez sur la page principale"
echo "2. Trouvez 'Internal Integration Secret' ou 'Token d'intégration interne'"
echo "3. Cliquez sur 'Afficher' puis 'Copier'"
echo ""
echo "Le token ressemble à : ntn_xxxxxxxxxxxxx ou secret_xxxxxxxxxxxxx"
echo ""
echo -e "${YELLOW}Collez votre token d'intégration Notion :${NC}"
read -rs NOTION_TOKEN
echo ""

# Validate token format
if [[ ! "$NOTION_TOKEN" =~ ^(ntn_|secret_) ]]; then
    echo -e "${RED}✗ Le token devrait commencer par 'ntn_' ou 'secret_'${NC}"
    echo "Assurez-vous de copier le token complet depuis la page de l'intégration."
    exit 1
fi

echo -e "${GREEN}✓ Format du token valide${NC}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Étape 4: Partager des Pages${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Important :${NC} L'intégration ne peut voir que les pages partagées avec elle."
echo ""
echo "Pour partager une page ou base de données :"
echo ""
echo "1. Ouvrez la page dans Notion"
echo "2. Cliquez sur '...' (menu) en haut à droite"
echo "3. Cliquez sur 'Connexions' ou 'Add connections'"
echo "4. Sélectionnez votre intégration"
echo ""
echo -e "${YELLOW}Astuce :${NC} Partagez une page parent pour donner accès à toutes ses sous-pages."
echo ""
echo -e "${YELLOW}Appuyez sur Entrée quand vous avez partagé au moins une page...${NC}"
read -r

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Étape 5: Configurer le Serveur MCP${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Ask for server name
echo "Quel nom voulez-vous donner à cette connexion Notion ?"
echo "(ex: 'notion', 'notion-work', 'notion-perso')"
echo ""
echo -e "${YELLOW}Nom du serveur [notion]:${NC}"
read -r SERVER_NAME
SERVER_NAME=${SERVER_NAME:-notion}

# Remove existing if present
claude mcp remove "$SERVER_NAME" 2>/dev/null || true

# Build the auth header JSON
AUTH_HEADER="{\"Authorization\": \"Bearer $NOTION_TOKEN\", \"Notion-Version\": \"2022-06-28\"}"

# Add Notion MCP server using the official package
claude mcp add "$SERVER_NAME" $SCOPE_FLAG \
    -e OPENAPI_MCP_HEADERS="$AUTH_HEADER" \
    -- npx -y @notionhq/notion-mcp-server

echo ""
echo -e "${GREEN}✓ Serveur MCP Notion ajouté sous le nom '${SERVER_NAME}'${NC}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Configuration Terminée !${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Redémarrez Claude Code, puis essayez :"
echo ""
echo -e "  ${YELLOW}\"Liste mes bases de données Notion\"${NC}"
echo -e "  ${YELLOW}\"Cherche dans Notion les notes de réunion\"${NC}"
echo -e "  ${YELLOW}\"Qu'est-ce qu'il y a dans ma page Projets ?\"${NC}"
echo -e "  ${YELLOW}\"Crée une nouvelle page dans mon wiki\"${NC}"
echo ""
echo -e "${GREEN}Vous êtes prêt !${NC}"
echo ""
