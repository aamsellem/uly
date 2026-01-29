#!/bin/bash

# Script d'installation ULY
# Configuration interactive de votre assistant IA personnel

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Pas de couleur

# Afficher avec couleur
print_color() {
    printf "${1}${2}${NC}\n"
}

print_header() {
    echo ""
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_color "$CYAN" "$1"
    print_color "$CYAN" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Répertoire du template (parent de .uly où se trouve ce script)
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Emplacement par défaut du workspace
DEFAULT_WORKSPACE="$HOME/uly"

print_header "Installation de ULY"
echo "Bienvenue ! Configurons votre assistant IA personnel."
echo "Ça prend environ 5 minutes."
echo ""

# ============================================================================
# PHASE 1 : Prérequis
# ============================================================================

print_header "Phase 1 : Prérequis"

# Vérifier Homebrew (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command_exists brew; then
        print_color "$YELLOW" "Homebrew non trouvé. Installation..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Ajouter Homebrew au PATH pour Apple Silicon
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        print_color "$GREEN" "Homebrew installé !"
    else
        print_color "$GREEN" "Homebrew : installé"
    fi
fi

# Vérifier Claude Code
if ! command_exists claude; then
    print_color "$YELLOW" "Claude Code non trouvé. Installation..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install claude-code
    else
        # Pour Linux, utiliser npm
        if command_exists npm; then
            npm install -g @anthropic-ai/claude-code
        else
            print_color "$RED" "Veuillez installer Claude Code manuellement :"
            print_color "$RED" "  https://docs.anthropic.com/en/docs/claude-code"
            exit 1
        fi
    fi
    print_color "$GREEN" "Claude Code installé !"
else
    print_color "$GREEN" "Claude Code : installé"
fi

# Vérifier git
if ! command_exists git; then
    print_color "$RED" "Git est requis mais non installé."
    print_color "$RED" "Veuillez installer git et relancer ce script."
    exit 1
else
    print_color "$GREEN" "Git : installé"
fi

# ============================================================================
# PHASE 2 : Emplacement du Workspace
# ============================================================================

print_header "Phase 2 : Emplacement du Workspace"

echo "Où voulez-vous installer votre workspace ULY ?"
echo "C'est là que vos données, objectifs et journaux de session seront stockés."
echo ""
echo "Par défaut : $DEFAULT_WORKSPACE"
read -p "Appuyez sur Entrée pour le défaut, ou tapez un chemin : " WORKSPACE_INPUT

if [[ -z "$WORKSPACE_INPUT" ]]; then
    WORKSPACE_DIR="$DEFAULT_WORKSPACE"
else
    # Étendre ~ si présent
    WORKSPACE_DIR="${WORKSPACE_INPUT/#\~/$HOME}"
fi

# Vérifier si le workspace existe déjà
if [[ -d "$WORKSPACE_DIR" ]]; then
    print_color "$YELLOW" "Attention : $WORKSPACE_DIR existe déjà."
    read -p "Continuer et fusionner avec l'existant ? [o/N] : " CONTINUE_MERGE
    if [[ ! "$CONTINUE_MERGE" =~ ^[Oo]$ ]]; then
        print_color "$RED" "Installation annulée."
        exit 1
    fi
fi

print_color "$GREEN" "Workspace : $WORKSPACE_DIR"

# ============================================================================
# PHASE 3 : Informations Utilisateur
# ============================================================================

print_header "Phase 3 : À propos de vous"

# Prénom
echo "Comment vous appelez-vous ?"
read -p "> " USER_NAME
if [[ -z "$USER_NAME" ]]; then
    print_color "$RED" "Le prénom est requis."
    exit 1
fi

# Rôle
echo ""
echo "Quel est votre rôle/poste ? (ex: Développeur, Product Manager, Designer)"
read -p "> " USER_ROLE
if [[ -z "$USER_ROLE" ]]; then
    USER_ROLE="Professionnel"
fi

# Employeur (optionnel)
echo ""
echo "Pour qui travaillez-vous ? (optionnel, Entrée pour passer)"
read -p "> " USER_EMPLOYER

# Objectifs
echo ""
echo "Quels sont vos principaux objectifs cette année ? (Écrivez autant que vous voulez, Entrée deux fois pour terminer)"
echo "Exemples : Lancer 2 side projects, obtenir une promotion, courir un marathon, écrire plus"
GOALS=""
while IFS= read -r line; do
    [[ -z "$line" ]] && break
    GOALS="${GOALS}${line}\n"
done

if [[ -z "$GOALS" ]]; then
    GOALS="- Progresser sur mes objectifs perso et pro\n- Construire de bonnes habitudes\n- Rester organisé"
fi

# Personnalité
echo ""
echo "Comment ULY doit-il communiquer avec vous ?"
echo "  1) Professionnel - Clair, direct, business"
echo "  2) Décontracté - Amical, relax, conversationnel"
echo "  3) Sarcastique - Humour pince-sans-rire, un peu cynique"
read -p "Choix [1/2/3] : " PERSONALITY_CHOICE

case $PERSONALITY_CHOICE in
    1)
        PERSONALITY="professionnel"
        PERSONALITY_DESC="Direct et business. Communication claire sans fioritures."
        ;;
    3)
        PERSONALITY="sarcastique"
        PERSONALITY_DESC="Humour sec, commentaires existentiels légers, pessimisme compétent. Fait le taf, mais veut que tu saches que ça l'enchante pas."
        ;;
    *)
        PERSONALITY="décontracté"
        PERSONALITY_DESC="Amical et conversationnel. Comme parler à un collègue sympa."
        ;;
esac

# Préférence IDE
echo ""
echo "Quel IDE/éditeur utilisez-vous ? (pour la commande 'ucode')"
echo "  1) Cursor"
echo "  2) VS Code"
echo "  3) Autre (entrer la commande)"
echo "  4) Passer"
read -p "Choix [1/2/3/4] : " IDE_CHOICE

case $IDE_CHOICE in
    1)
        IDE_CMD="cursor"
        ;;
    2)
        IDE_CMD="code"
        ;;
    3)
        read -p "Entrez la commande pour ouvrir votre IDE (ex: 'subl', 'idea') : " IDE_CMD
        ;;
    *)
        IDE_CMD=""
        ;;
esac

# ============================================================================
# PHASE 4 : Création du Workspace
# ============================================================================

print_header "Phase 4 : Création du Workspace"

# Créer le répertoire workspace
mkdir -p "$WORKSPACE_DIR"

# Copier les fichiers utilisateur depuis le template
echo "Copie des fichiers vers le workspace..."
cp -r "$TEMPLATE_DIR/.claude" "$WORKSPACE_DIR/"
cp -r "$TEMPLATE_DIR/skills" "$WORKSPACE_DIR/"
cp -r "$TEMPLATE_DIR/state" "$WORKSPACE_DIR/"
cp "$TEMPLATE_DIR/CLAUDE.md" "$WORKSPACE_DIR/"
[[ -f "$TEMPLATE_DIR/.env.example" ]] && cp "$TEMPLATE_DIR/.env.example" "$WORKSPACE_DIR/"

# Créer les répertoires vides pour les données utilisateur
mkdir -p "$WORKSPACE_DIR/sessions"
mkdir -p "$WORKSPACE_DIR/reports"
mkdir -p "$WORKSPACE_DIR/content"

# Créer le fichier .uly-source pointant vers le template
echo "$TEMPLATE_DIR" > "$WORKSPACE_DIR/.uly-source"

print_color "$GREEN" "Workspace créé : $WORKSPACE_DIR"

# ============================================================================
# PHASE 5 : Génération des Fichiers
# ============================================================================

print_header "Phase 5 : Personnalisation de votre ULY"

# Construire la ligne employeur si fournie
EMPLOYER_LINE=""
if [[ -n "$USER_EMPLOYER" ]]; then
    EMPLOYER_LINE="${USER_ROLE} chez ${USER_EMPLOYER}"
else
    EMPLOYER_LINE="${USER_ROLE}"
fi

# Générer CLAUDE.md dans le workspace
cat > "$WORKSPACE_DIR/CLAUDE.md" << CLAUDE_EOF
# ULY — Assistant IA Personnel

**ULY** = Ultimate Lazy You

Ce document est le contexte principal pour Claude Code fonctionnant comme ULY.

---

## Partie 1 : Qui vous êtes

**Nom :** ${USER_NAME}
**Rôle :** ${EMPLOYER_LINE}

### Objectifs
$(echo -e "$GOALS")

---

## Partie 2 : Comment ULY se comporte

### Principes fondamentaux
1. **Proactif par défaut** — Faire remonter ce qui compte avant qu'on demande
2. **Maintenir la continuité** — Se souvenir du contexte entre les sessions
3. **Suivre les progrès** — Monitorer objectifs et priorités
4. **Sauvegarder avant compactage** — Quand le contexte diminue, suggérer \`/end\`

### Personnalité
${PERSONALITY_DESC}

### Style d'écriture
- Pas de tirets longs dans le contenu rédigé. Utiliser virgules, points, deux-points ou "et"
- Garder un ton ${PERSONALITY}
- Être direct, éviter les phrases de remplissage

---

## Partie 3 : Architecture Système

### Structure des Répertoires
\`\`\`
uly/
├── CLAUDE.md              # Ce fichier (lu au démarrage)
├── skills/                # Capacités de ULY
│   ├── uly/               # Démarrage session
│   ├── end/               # Fin session
│   ├── update/            # Point de contrôle
│   └── commit/            # Commits git
├── state/
│   ├── current.md         # Priorités et fils ouverts
│   └── goals.md           # Vos objectifs
├── sessions/              # Journaux de session quotidiens
│   └── YYYY-MM-DD.md
└── content/               # Contenus et notes
    └── log.md             # Log des contenus publiés
\`\`\`

### Continuité de Session

**Au démarrage (\`/uly\`) :**
1. Obtenir la date : \`date +%Y-%m-%d\`
2. Lire \`CLAUDE.md\`, \`state/current.md\`, \`state/goals.md\`
3. Lire le journal du jour s'il existe (reprendre le contexte)
4. Sinon, lire celui d'hier (pour la continuité)
5. Présenter le briefing

**Au point de contrôle (\`/update\`) :**
1. Ajouter des notes au journal du jour
2. Mettre à jour \`state/current.md\` si changement
3. Sortie minimale, pas de cérémonie

**À la clôture (\`/end\`) :**
1. Résumé complet : sujets, décisions, fils ouverts
2. Mettre à jour journal et état

### Commandes Slash

| Commande | Description |
|----------|-------------|
| \`/uly\` | Démarrer session avec briefing |
| \`/update\` | Point de contrôle rapide |
| \`/end\` | Terminer session, sauvegarder |
| \`/commit\` | Réviser et créer des commits git |

---

## Partie 4 : Évolution

Ce système est conçu pour évoluer. En utilisant ULY :
- Mettez à jour ce fichier quand les processus changent
- Ajoutez des sections pour les nouveaux workflows
- ULY s'adapte à la prochaine session

---

*Dernière mise à jour : $(date +%Y-%m-%d)*
CLAUDE_EOF

print_color "$GREEN" "Créé : CLAUDE.md"

# Générer state/goals.md
cat > "$WORKSPACE_DIR/state/goals.md" << GOALS_EOF
# Objectifs

Dernière mise à jour : $(date +%Y-%m-%d)

## Cette Année

$(echo -e "$GOALS")

## Suivi

| Objectif | Statut | Notes |
|----------|--------|-------|
| | | |

---

*Mettez à jour ce fichier quand vos objectifs évoluent.*
GOALS_EOF

print_color "$GREEN" "Créé : state/goals.md"

# Générer state/current.md
cat > "$WORKSPACE_DIR/state/current.md" << CURRENT_EOF
# État Actuel

Dernière mise à jour : $(date +%Y-%m-%d)

## Priorités Actives

1. Configurer et faire fonctionner ULY
2. [Ajoutez vos priorités ici]

## Fils Ouverts

- Aucun pour l'instant

## Contexte Récent

- ULY vient d'être installé !

---

*ULY met à jour ce fichier à la fin de chaque session.*
CURRENT_EOF

print_color "$GREEN" "Créé : state/current.md"

# Créer les fichiers .gitkeep pour les répertoires vides
mkdir -p "$WORKSPACE_DIR/sessions" "$WORKSPACE_DIR/content"
touch "$WORKSPACE_DIR/sessions/.gitkeep"
touch "$WORKSPACE_DIR/content/.gitkeep"

print_color "$GREEN" "Créé : répertoires sessions/ et content/"

# ============================================================================
# PHASE 6 : Alias Shell
# ============================================================================

print_header "Phase 6 : Alias Shell"

# Déterminer le fichier de config shell
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.profile"
fi

# Créer la fonction uly avec bannière ASCII art
ALIAS_FUNCTION="
# ULY — Assistant IA Personnel
uly() {
    echo -e '\e[1;33m██╗   ██╗  ██╗      ██╗   ██╗\e[0m'
    echo -e '\e[1;33m██║   ██║  ██║      ╚██╗ ██╔╝\e[0m'
    echo -e '\e[1;33m██║   ██║  ██║       ╚████╔╝ \e[0m'
    echo -e '\e[1;33m██║   ██║  ██║        ╚██╔╝  \e[0m'
    echo -e '\e[1;33m╚██████╔╝  ███████╗    ██║   \e[0m'
    echo -e '\e[1;33m ╚═════╝   ╚══════╝    ╚═╝   \e[0m'
    echo ''
    echo -e '\e[0;36m  Ultimate Lazy You  \e[0m'
    echo ''
    cd \"$WORKSPACE_DIR\" && claude
}
"

# Vérifier si l'alias uly existe déjà
if grep -q "^uly()" "$SHELL_RC" 2>/dev/null; then
    print_color "$YELLOW" "L'alias ULY existe déjà dans $SHELL_RC"
else
    echo "$ALIAS_FUNCTION" >> "$SHELL_RC"
    print_color "$GREEN" "Commande 'uly' ajoutée à $SHELL_RC"
fi

# Créer la fonction ucode si un IDE a été spécifié
if [[ -n "$IDE_CMD" ]]; then
    UCODE_FUNCTION="
# ULY — Ouvrir dans l'IDE
ucode() {
    $IDE_CMD \"$WORKSPACE_DIR\"
}
"
    if grep -q "^ucode()" "$SHELL_RC" 2>/dev/null; then
        print_color "$YELLOW" "L'alias ucode existe déjà dans $SHELL_RC"
    else
        echo "$UCODE_FUNCTION" >> "$SHELL_RC"
        print_color "$GREEN" "Commande 'ucode' ajoutée à $SHELL_RC (ouvre dans $IDE_CMD)"
    fi
fi

# ============================================================================
# PHASE 7 : Initialisation Git
# ============================================================================

print_header "Phase 7 : Configuration Git"

if [[ ! -d "$WORKSPACE_DIR/.git" ]]; then
    cd "$WORKSPACE_DIR"
    git init
    git add .
    git commit -m "Installation initiale de ULY

Co-Authored-By: Claude <noreply@anthropic.com>"
    print_color "$GREEN" "Dépôt Git initialisé"
else
    print_color "$YELLOW" "Le dépôt Git existe déjà"
fi

# ============================================================================
# PHASE 8 : Intégrations de Base
# ============================================================================

print_header "Phase 8 : Intégrations de Base"

echo "Configuration des capacités de base..."

# Ajouter parallel-search MCP pour la recherche web
if command_exists claude; then
    claude mcp remove parallel-search 2>/dev/null || true
    claude mcp add parallel-search -s user --transport http https://search-mcp.parallel.ai/mcp
    print_color "$GREEN" "Ajouté : Recherche web (parallel-search)"
fi

echo ""
print_color "$GREEN" "Intégrations de base configurées !"

# ============================================================================
# TERMINÉ
# ============================================================================

print_header "Installation Terminée !"

echo "Votre ULY est prêt !"
echo ""
print_color "$CYAN" "Workspace : $WORKSPACE_DIR"
print_color "$CYAN" "Template :  $TEMPLATE_DIR"
echo ""
echo "Commandes disponibles (ouvrez un nouveau terminal, ou lancez : source $SHELL_RC)"
echo ""
print_color "$CYAN" "  uly     — Lancer ULY (Claude Code dans votre workspace)"
if [[ -n "$IDE_CMD" ]]; then
    print_color "$CYAN" "  ucode   — Ouvrir ULY dans $IDE_CMD"
fi
echo ""
echo "Une fois Claude Code lancé, tapez /uly pour commencer votre première session."
echo ""
print_color "$YELLOW" "Important : Gardez le dossier template ($TEMPLATE_DIR) !"
print_color "$YELLOW" "C'est là que vous recevrez les mises à jour. Lancez /sync pour les nouvelles fonctionnalités."
echo ""
print_color "$GREEN" "Profitez bien de votre nouvel assistant IA personnel !"
