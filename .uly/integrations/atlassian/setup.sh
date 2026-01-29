#!/bin/bash
# Atlassian MCP Setup Script
# For Postman team members using Claude Code
# Created by Sterling Chin

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Atlassian MCP Setup (Jira/Confluence)${NC}"
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
echo -e "${BLUE}Adding Atlassian MCP to Claude Code...${NC}"

# Remove existing if present
claude mcp remove atlassian 2>/dev/null || true

# Add Atlassian remote MCP server
claude mcp add atlassian $SCOPE_FLAG --transport http https://mcp.atlassian.com/v1/mcp

echo ""
echo -e "${GREEN}Atlassian MCP added!${NC}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Authentication${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Now you need to authenticate with Atlassian."
echo ""
echo -e "${YELLOW}Run this command:${NC}"
echo ""
echo "    claude mcp"
echo ""
echo "Then:"
echo "  1. Find 'atlassian' in the list and select it"
echo "  2. Choose 'Authenticate'"
echo "  3. Complete the login in your browser"
echo ""
read -p "Press Enter once you've authenticated (or 's' to skip)... " AUTH_RESPONSE

if [[ "$AUTH_RESPONSE" == "s" || "$AUTH_RESPONSE" == "S" ]]; then
    echo ""
    echo -e "${YELLOW}Skipped authentication.${NC}"
    echo "Remember to run 'claude mcp' and authenticate before using Jira/Confluence."
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Try it out in Claude Code:"
echo -e "     ${YELLOW}\"Show me my open Jira tickets\"${NC}"
echo -e "     ${YELLOW}\"Search Confluence for API documentation\"${NC}"
echo ""
echo -e "${GREEN}You're all set!${NC}"
echo ""
