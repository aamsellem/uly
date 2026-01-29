#!/bin/bash

# ULY Migration Script
# Migrates existing ULY users to the new workspace separation architecture

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

# Get the template directory (parent of .uly where this script lives)
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_WORKSPACE="$HOME/uly"

print_header "ULY Migration"

echo "This script migrates your existing ULY to the new workspace architecture."
echo ""
echo "Your personal data (goals, sessions, profile) will be preserved."
echo "The template will be kept separate so you can get updates easily."
echo ""

# Ask for the location of their current ULY
echo "Where is your current ULY installation?"
echo "(This is the folder with your CLAUDE.md, state/, sessions/, etc.)"
echo ""
read -p "Path to current ULY [press Enter if this IS your current ULY]: " CURRENT_ULY

if [[ -z "$CURRENT_ULY" ]]; then
    CURRENT_ULY="$TEMPLATE_DIR"
fi

# Expand ~ if present
CURRENT_ULY="${CURRENT_ULY/#\~/$HOME}"

# Verify it looks like a ULY installation
if [[ ! -f "$CURRENT_ULY/CLAUDE.md" ]]; then
    print_color "$RED" "Error: Can't find CLAUDE.md in $CURRENT_ULY"
    print_color "$RED" "This doesn't look like a ULY installation."
    exit 1
fi

print_color "$GREEN" "Found ULY at: $CURRENT_ULY"

# Check what user data exists
echo ""
echo "Found the following user data:"
[[ -f "$CURRENT_ULY/CLAUDE.md" ]] && echo "  - CLAUDE.md (your profile)"
[[ -d "$CURRENT_ULY/state" ]] && echo "  - state/ (goals and priorities)"
[[ -d "$CURRENT_ULY/sessions" ]] && [[ "$(ls -A "$CURRENT_ULY/sessions" 2>/dev/null)" ]] && echo "  - sessions/ ($(ls "$CURRENT_ULY/sessions" | wc -l | tr -d ' ') session logs)"
[[ -d "$CURRENT_ULY/reports" ]] && [[ "$(ls -A "$CURRENT_ULY/reports" 2>/dev/null)" ]] && echo "  - reports/ (weekly reports)"
[[ -d "$CURRENT_ULY/content" ]] && [[ "$(ls -A "$CURRENT_ULY/content" 2>/dev/null)" ]] && echo "  - content/ (your content)"
[[ -f "$CURRENT_ULY/.env" ]] && echo "  - .env (your secrets)"

# Ask for workspace location
echo ""
echo "Where would you like your new ULY workspace?"
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
echo "  From: $CURRENT_ULY"
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
if [[ -f "$CURRENT_ULY/CLAUDE.md" ]]; then
    cp "$CURRENT_ULY/CLAUDE.md" "$WORKSPACE_DIR/"
    print_color "$GREEN" "  Copied: CLAUDE.md"
fi

# state/ - goals and priorities
if [[ -d "$CURRENT_ULY/state" ]]; then
    cp -r "$CURRENT_ULY/state/"* "$WORKSPACE_DIR/state/" 2>/dev/null || true
    print_color "$GREEN" "  Copied: state/"
fi

# sessions/ - session logs
if [[ -d "$CURRENT_ULY/sessions" ]] && [[ "$(ls -A "$CURRENT_ULY/sessions" 2>/dev/null)" ]]; then
    cp -r "$CURRENT_ULY/sessions/"* "$WORKSPACE_DIR/sessions/" 2>/dev/null || true
    print_color "$GREEN" "  Copied: sessions/"
fi

# reports/ - weekly reports
if [[ -d "$CURRENT_ULY/reports" ]] && [[ "$(ls -A "$CURRENT_ULY/reports" 2>/dev/null)" ]]; then
    cp -r "$CURRENT_ULY/reports/"* "$WORKSPACE_DIR/reports/" 2>/dev/null || true
    print_color "$GREEN" "  Copied: reports/"
fi

# content/ - user content
if [[ -d "$CURRENT_ULY/content" ]] && [[ "$(ls -A "$CURRENT_ULY/content" 2>/dev/null)" ]]; then
    cp -r "$CURRENT_ULY/content/"* "$WORKSPACE_DIR/content/" 2>/dev/null || true
    print_color "$GREEN" "  Copied: content/"
fi

# .env - secrets
if [[ -f "$CURRENT_ULY/.env" ]]; then
    cp "$CURRENT_ULY/.env" "$WORKSPACE_DIR/"
    print_color "$GREEN" "  Copied: .env"
fi

# Custom skills (check for any that aren't in template)
if [[ -d "$CURRENT_ULY/skills" ]]; then
    for skill_dir in "$CURRENT_ULY/skills/"*/; do
        skill_name=$(basename "$skill_dir")
        if [[ ! -d "$TEMPLATE_DIR/skills/$skill_name" ]]; then
            cp -r "$skill_dir" "$WORKSPACE_DIR/skills/"
            print_color "$GREEN" "  Copied custom skill: $skill_name"
        fi
    done
fi

# Create .uly-source file pointing to template
echo "$TEMPLATE_DIR" > "$WORKSPACE_DIR/.uly-source"
print_color "$GREEN" "  Created: .uly-source"

# Initialize git if not present
if [[ ! -d "$WORKSPACE_DIR/.git" ]]; then
    echo ""
    echo "Initializing git repository..."
    cd "$WORKSPACE_DIR"
    git init
    git add .
    git commit -m "Migrate to ULY workspace architecture

Migrated from: $CURRENT_ULY

Co-Authored-By: Claude <noreply@anthropic.com>"
    print_color "$GREEN" "Git repository initialized"
fi

print_header "Migration Complete!"

echo "Your ULY workspace is now at: $WORKSPACE_DIR"
echo ""
echo "Your data has been preserved:"
echo "  - Profile, goals, sessions, reports, content"
echo "  - Any custom skills you created"
echo ""
print_color "$CYAN" "Next steps:"
echo "  1. Open your new workspace: cd $WORKSPACE_DIR && claude"
echo "  2. Start a session: /uly"
echo ""
print_color "$YELLOW" "Important:"
echo "  - Keep the template folder ($TEMPLATE_DIR) for updates"
echo "  - Run /sync anytime to get new features"
echo "  - Your old installation at $CURRENT_ULY can be deleted once you verify everything works"
echo ""
print_color "$GREEN" "Enjoy your upgraded ULY!"
