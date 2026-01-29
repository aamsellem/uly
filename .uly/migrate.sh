#!/bin/bash

# MARVIN Migration Script
# Migrates existing MARVIN users to the new workspace separation architecture

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

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

# Get the template directory (parent of .marvin where this script lives)
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_WORKSPACE="$HOME/marvin"

print_header "MARVIN Migration"

echo "This script migrates your existing MARVIN to the new workspace architecture."
echo ""
echo "Your personal data (goals, sessions, profile) will be preserved."
echo "The template will be kept separate so you can get updates easily."
echo ""

# Ask for the location of their current MARVIN
echo "Where is your current MARVIN installation?"
echo "(This is the folder with your CLAUDE.md, state/, sessions/, etc.)"
echo ""
read -p "Path to current MARVIN [press Enter if this IS your current MARVIN]: " CURRENT_MARVIN

if [[ -z "$CURRENT_MARVIN" ]]; then
    CURRENT_MARVIN="$TEMPLATE_DIR"
fi

# Expand ~ if present
CURRENT_MARVIN="${CURRENT_MARVIN/#\~/$HOME}"

# Verify it looks like a MARVIN installation
if [[ ! -f "$CURRENT_MARVIN/CLAUDE.md" ]]; then
    print_color "$RED" "Error: Can't find CLAUDE.md in $CURRENT_MARVIN"
    print_color "$RED" "This doesn't look like a MARVIN installation."
    exit 1
fi

print_color "$GREEN" "Found MARVIN at: $CURRENT_MARVIN"

# Check what user data exists
echo ""
echo "Found the following user data:"
[[ -f "$CURRENT_MARVIN/CLAUDE.md" ]] && echo "  - CLAUDE.md (your profile)"
[[ -d "$CURRENT_MARVIN/state" ]] && echo "  - state/ (goals and priorities)"
[[ -d "$CURRENT_MARVIN/sessions" ]] && [[ "$(ls -A "$CURRENT_MARVIN/sessions" 2>/dev/null)" ]] && echo "  - sessions/ ($(ls "$CURRENT_MARVIN/sessions" | wc -l | tr -d ' ') session logs)"
[[ -d "$CURRENT_MARVIN/reports" ]] && [[ "$(ls -A "$CURRENT_MARVIN/reports" 2>/dev/null)" ]] && echo "  - reports/ (weekly reports)"
[[ -d "$CURRENT_MARVIN/content" ]] && [[ "$(ls -A "$CURRENT_MARVIN/content" 2>/dev/null)" ]] && echo "  - content/ (your content)"
[[ -f "$CURRENT_MARVIN/.env" ]] && echo "  - .env (your secrets)"

# Ask for workspace location
echo ""
echo "Where would you like your new MARVIN workspace?"
echo "Default: $DEFAULT_WORKSPACE"
read -p "Press Enter for default, or type a path: " WORKSPACE_INPUT

if [[ -z "$WORKSPACE_INPUT" ]]; then
    WORKSPACE_DIR="$DEFAULT_WORKSPACE"
else
    WORKSPACE_DIR="${WORKSPACE_INPUT/#\~/$HOME}"
fi

# Check if workspace already exists
if [[ -d "$WORKSPACE_DIR" ]]; then
    print_color "$YELLOW" "Warning: $WORKSPACE_DIR already exists."
    read -p "Continue and merge? [y/N]: " CONTINUE_MERGE
    if [[ ! "$CONTINUE_MERGE" =~ ^[Yy]$ ]]; then
        print_color "$RED" "Migration cancelled."
        exit 1
    fi
fi

# Confirm before proceeding
echo ""
print_color "$YELLOW" "Migration plan:"
echo "  From: $CURRENT_MARVIN"
echo "  To:   $WORKSPACE_DIR"
echo "  Template: $TEMPLATE_DIR"
echo ""
read -p "Proceed with migration? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    print_color "$RED" "Migration cancelled."
    exit 1
fi

print_header "Migrating..."

# Create workspace directory
mkdir -p "$WORKSPACE_DIR"

# Copy latest template files first (commands, skills structure)
echo "Copying latest template files..."
cp -r "$TEMPLATE_DIR/.claude" "$WORKSPACE_DIR/" 2>/dev/null || true
cp -r "$TEMPLATE_DIR/skills" "$WORKSPACE_DIR/" 2>/dev/null || true
[[ -f "$TEMPLATE_DIR/.env.example" ]] && cp "$TEMPLATE_DIR/.env.example" "$WORKSPACE_DIR/"

# Create directories
mkdir -p "$WORKSPACE_DIR/sessions"
mkdir -p "$WORKSPACE_DIR/reports"
mkdir -p "$WORKSPACE_DIR/content"
mkdir -p "$WORKSPACE_DIR/state"

# Now copy user's personal data (overwriting template defaults)
echo "Copying your personal data..."

# CLAUDE.md - user's profile
if [[ -f "$CURRENT_MARVIN/CLAUDE.md" ]]; then
    cp "$CURRENT_MARVIN/CLAUDE.md" "$WORKSPACE_DIR/"
    print_color "$GREEN" "  Copied: CLAUDE.md"
fi

# state/ - goals and priorities
if [[ -d "$CURRENT_MARVIN/state" ]]; then
    cp -r "$CURRENT_MARVIN/state/"* "$WORKSPACE_DIR/state/" 2>/dev/null || true
    print_color "$GREEN" "  Copied: state/"
fi

# sessions/ - session logs
if [[ -d "$CURRENT_MARVIN/sessions" ]] && [[ "$(ls -A "$CURRENT_MARVIN/sessions" 2>/dev/null)" ]]; then
    cp -r "$CURRENT_MARVIN/sessions/"* "$WORKSPACE_DIR/sessions/" 2>/dev/null || true
    print_color "$GREEN" "  Copied: sessions/"
fi

# reports/ - weekly reports
if [[ -d "$CURRENT_MARVIN/reports" ]] && [[ "$(ls -A "$CURRENT_MARVIN/reports" 2>/dev/null)" ]]; then
    cp -r "$CURRENT_MARVIN/reports/"* "$WORKSPACE_DIR/reports/" 2>/dev/null || true
    print_color "$GREEN" "  Copied: reports/"
fi

# content/ - user content
if [[ -d "$CURRENT_MARVIN/content" ]] && [[ "$(ls -A "$CURRENT_MARVIN/content" 2>/dev/null)" ]]; then
    cp -r "$CURRENT_MARVIN/content/"* "$WORKSPACE_DIR/content/" 2>/dev/null || true
    print_color "$GREEN" "  Copied: content/"
fi

# .env - secrets
if [[ -f "$CURRENT_MARVIN/.env" ]]; then
    cp "$CURRENT_MARVIN/.env" "$WORKSPACE_DIR/"
    print_color "$GREEN" "  Copied: .env"
fi

# Custom skills (check for any that aren't in template)
if [[ -d "$CURRENT_MARVIN/skills" ]]; then
    for skill_dir in "$CURRENT_MARVIN/skills/"*/; do
        skill_name=$(basename "$skill_dir")
        if [[ ! -d "$TEMPLATE_DIR/skills/$skill_name" ]]; then
            cp -r "$skill_dir" "$WORKSPACE_DIR/skills/"
            print_color "$GREEN" "  Copied custom skill: $skill_name"
        fi
    done
fi

# Create .marvin-source file pointing to template
echo "$TEMPLATE_DIR" > "$WORKSPACE_DIR/.marvin-source"
print_color "$GREEN" "  Created: .marvin-source"

# Initialize git if not present
if [[ ! -d "$WORKSPACE_DIR/.git" ]]; then
    echo ""
    echo "Initializing git repository..."
    cd "$WORKSPACE_DIR"
    git init
    git add .
    git commit -m "Migrate to MARVIN workspace architecture

Migrated from: $CURRENT_MARVIN

Co-Authored-By: Claude <noreply@anthropic.com>"
    print_color "$GREEN" "Git repository initialized"
fi

print_header "Migration Complete!"

echo "Your MARVIN workspace is now at: $WORKSPACE_DIR"
echo ""
echo "Your data has been preserved:"
echo "  - Profile, goals, sessions, reports, content"
echo "  - Any custom skills you created"
echo ""
print_color "$CYAN" "Next steps:"
echo "  1. Open your new workspace: cd $WORKSPACE_DIR && claude"
echo "  2. Start a session: /marvin"
echo ""
print_color "$YELLOW" "Important:"
echo "  - Keep the template folder ($TEMPLATE_DIR) for updates"
echo "  - Run /sync anytime to get new features"
echo "  - Your old installation at $CURRENT_MARVIN can be deleted once you verify everything works"
echo ""
print_color "$GREEN" "Enjoy your upgraded MARVIN!"
