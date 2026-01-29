#!/bin/bash
# Slack MCP Setup Script
# Connect MARVIN to your Slack workspace

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Slack MCP Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check Claude Code
if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Claude Code installed${NC}"
else
    echo -e "${RED}✗ Claude Code not found${NC}"
    echo "Install with: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# Check Node.js first, then ask about scope
# (scope question comes after all checks)
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓ Node.js installed${NC}"
else
    echo -e "${RED}✗ Node.js not found${NC}"
    echo "Please install Node.js first: https://nodejs.org"
    exit 1
fi

# Scope selection
echo ""
echo "Where should this integration be available?"
echo "  1) All projects (user-scoped)"
echo "  2) This project only (project-scoped)"
echo ""
echo -e "${YELLOW}Choice [1]:${NC}"
read -r SCOPE_CHOICE
SCOPE_CHOICE=${SCOPE_CHOICE:-1}

if [[ "$SCOPE_CHOICE" == "1" ]]; then
    SCOPE_FLAG="-s user"
else
    SCOPE_FLAG=""
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Step 1: Create a Slack App${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "You'll need a Slack User Token (xoxp-...) with the right permissions."
echo ""
echo "1. Go to: https://api.slack.com/apps"
echo "2. Click 'Create New App' → 'From scratch'"
echo "3. Name it something like 'MARVIN' and select your workspace"
echo ""
echo -e "${YELLOW}Press Enter when you've created the app...${NC}"
read -r

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Step 2: Add Permissions${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "In your Slack app settings:"
echo ""
echo "1. Go to 'OAuth & Permissions' in the sidebar"
echo "2. Scroll to 'User Token Scopes'"
echo "3. Add these scopes:"
echo ""
echo -e "   ${YELLOW}channels:history${NC}     - Read messages in public channels"
echo -e "   ${YELLOW}channels:read${NC}        - View basic channel info"
echo -e "   ${YELLOW}chat:write${NC}           - Send messages"
echo -e "   ${YELLOW}groups:history${NC}       - Read messages in private channels"
echo -e "   ${YELLOW}groups:read${NC}          - View private channel info"
echo -e "   ${YELLOW}im:history${NC}           - Read direct messages"
echo -e "   ${YELLOW}im:read${NC}              - View DM info"
echo -e "   ${YELLOW}mpim:history${NC}         - Read group DMs"
echo -e "   ${YELLOW}mpim:read${NC}            - View group DM info"
echo -e "   ${YELLOW}search:read${NC}          - Search messages"
echo -e "   ${YELLOW}users:read${NC}           - View user info"
echo ""
echo "4. Click 'Install to Workspace' at the top"
echo "5. Authorize the app"
echo ""
echo -e "${YELLOW}Press Enter when you've installed the app...${NC}"
read -r

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Step 3: Copy Your Token${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "After installing, you'll see a 'User OAuth Token' starting with xoxp-"
echo ""
echo -e "${YELLOW}Paste your Slack User Token (xoxp-...):${NC}"
read -rs SLACK_TOKEN
echo ""

# Validate token format
if [[ ! "$SLACK_TOKEN" =~ ^xoxp- ]]; then
    echo -e "${RED}✗ Token should start with 'xoxp-'${NC}"
    echo "Make sure you're copying the User OAuth Token, not the Bot token."
    exit 1
fi

echo -e "${GREEN}✓ Token format looks good${NC}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Step 4: Configure MCP Server${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Ask for server name
echo "What would you like to name this Slack connection?"
echo "(e.g., 'slack-work', 'slack-personal', or just 'slack')"
echo ""
echo -e "${YELLOW}Server name [slack]:${NC}"
read -r SERVER_NAME
SERVER_NAME=${SERVER_NAME:-slack}

# Remove existing if present
claude mcp remove "$SERVER_NAME" 2>/dev/null || true

# Add Slack MCP server
claude mcp add "$SERVER_NAME" $SCOPE_FLAG \
    -e SLACK_MCP_XOXP_TOKEN="$SLACK_TOKEN" \
    -- npx -y slack-mcp-server@latest --transport stdio

echo ""
echo -e "${GREEN}✓ Slack MCP server added as '${SERVER_NAME}'${NC}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Restart Claude Code, then try:"
echo ""
echo -e "  ${YELLOW}\"List my Slack channels\"${NC}"
echo -e "  ${YELLOW}\"Search Slack for project updates\"${NC}"
echo -e "  ${YELLOW}\"Show recent messages in #general\"${NC}"
echo -e "  ${YELLOW}\"Send a message to #random saying hello\"${NC}"
echo ""
echo -e "${GREEN}You're all set!${NC}"
echo ""
