#!/bin/bash
# Microsoft 365 Setup for Claude Code
#
# This sets up MS 365 MCP for Outlook, Calendar, OneDrive, Teams, etc.
# Uses device flow authentication (no API keys required)
#
# MCP Package: https://github.com/softeria-eu/ms-365-mcp-server

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Microsoft 365 Setup for Claude${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

if command -v npx &> /dev/null; then
    echo -e "${GREEN}✓ npx installed${NC}"
else
    echo -e "${RED}✗ npx not found${NC}"
    echo "  Install Node.js from https://nodejs.org"
    exit 1
fi

if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Claude Code installed${NC}"
else
    echo -e "${RED}✗ Claude Code not found${NC}"
    echo "  Install: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# Scope selection
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Configuration${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Where should this integration be available?"
echo "  1) All projects (user-scoped)"
echo "  2) This project only (project-scoped)"
echo ""
echo -n -e "${YELLOW}Choice [1]: ${NC}"
read -r SCOPE_CHOICE
SCOPE_CHOICE=${SCOPE_CHOICE:-1}

if [[ "$SCOPE_CHOICE" == "1" ]]; then
    SCOPE_FLAG="-s user"
else
    SCOPE_FLAG=""
fi

# Account type selection
echo ""
echo "What type of Microsoft account will you use?"
echo "  1) Work/School account (Microsoft 365 Business)"
echo "  2) Personal account only (outlook.com, hotmail.com)"
echo ""
echo -n -e "${YELLOW}Choice [1]: ${NC}"
read -r ACCOUNT_CHOICE
ACCOUNT_CHOICE=${ACCOUNT_CHOICE:-1}

if [[ "$ACCOUNT_CHOICE" == "1" ]]; then
    ORG_FLAG="--org-mode"
else
    ORG_FLAG=""
fi

# Preset selection
echo ""
echo "Which Microsoft 365 tools do you need?"
echo "  1) All tools (Mail, Calendar, Files, Teams, SharePoint, etc.)"
echo "  2) Essentials only (Mail, Calendar, Files) - fewer permissions needed"
echo ""
echo -e "${YELLOW}Note:${NC} 'Essentials' may avoid admin consent requirements for work accounts."
echo ""
echo -n -e "${YELLOW}Choice [1]: ${NC}"
read -r PRESET_CHOICE
PRESET_CHOICE=${PRESET_CHOICE:-1}

if [[ "$PRESET_CHOICE" == "2" ]]; then
    PRESET_FLAG="--preset mail,calendar,files"
else
    PRESET_FLAG=""
fi

# Remove existing MCP if present
echo ""
echo -e "${BLUE}Configuring Microsoft 365 MCP...${NC}"
claude mcp remove ms365 2>/dev/null || true

# Build and run the command
CMD="claude mcp add ms365 $SCOPE_FLAG -- npx -y @softeria/ms-365-mcp-server"
[[ -n "$ORG_FLAG" ]] && CMD="$CMD $ORG_FLAG"
[[ -n "$PRESET_FLAG" ]] && CMD="$CMD $PRESET_FLAG"

echo "Running: $CMD"
eval $CMD

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Authentication${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Now you need to authenticate with Microsoft."
echo ""
echo -e "${YELLOW}Run this command:${NC}"
echo ""
echo "    claude mcp"
echo ""
echo "Then:"
echo "  1. Find 'ms365' in the list and select it"
echo "  2. Choose 'Authenticate'"
echo "  3. Visit the URL shown and enter the device code"
echo "  4. Sign in with your Microsoft account"
echo ""
read -p "Press Enter once you've authenticated (or 's' to skip)... " AUTH_RESPONSE

if [[ "$AUTH_RESPONSE" == "s" || "$AUTH_RESPONSE" == "S" ]]; then
    echo ""
    echo -e "${YELLOW}Skipped authentication.${NC}"
    echo "Remember to run 'claude mcp' and authenticate before using MS 365 tools."
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Try it out in Claude Code:"
echo -e "     ${YELLOW}\"What's on my Outlook calendar today?\"${NC}"
echo ""

# Show config summary
echo -e "${BLUE}Configuration:${NC}"
[[ "$SCOPE_CHOICE" == "1" ]] && echo "  • Scope: User (all projects)" || echo "  • Scope: Project (this project only)"
[[ "$ACCOUNT_CHOICE" == "1" ]] && echo "  • Account: Work/School (org-mode)" || echo "  • Account: Personal only"
[[ "$PRESET_CHOICE" == "2" ]] && echo "  • Tools: Essentials (mail, calendar, files)" || echo "  • Tools: All"
echo ""
