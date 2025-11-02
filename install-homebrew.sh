#!/usr/bin/env bash

# One-command installer for claude-swap via Homebrew
# Usage: curl -fsSL https://raw.githubusercontent.com/chicali/homebrew-claude-swap/main/install-homebrew.sh | bash

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Claude Swap - Homebrew Installer        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Homebrew is not installed.${NC}"
    echo ""
    echo "Please install Homebrew first:"
    echo -e "${YELLOW}  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓${NC} Homebrew is installed"
echo ""

# Check for jq
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Installing jq (required dependency)...${NC}"
    brew install jq
fi

echo -e "${GREEN}✓${NC} jq is installed"
echo ""

# Tap the repository
TAP_URL="chicali/claude-swap"
echo -e "${BLUE}Tapping ${TAP_URL}...${NC}"
brew tap "$TAP_URL"

echo -e "${GREEN}✓${NC} Tapped repository"
echo ""

# Install claude-swap
echo -e "${BLUE}Installing claude-swap...${NC}"
brew install claude-swap

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Installation Complete! 🎉            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${RED}⚠️  IMPORTANT: Configure Your Credentials! ⚠️${NC}"
echo ""
echo -e "${BLUE}Before using claude-swap, you MUST set up your API credentials:${NC}"
echo ""
echo -e "${YELLOW}Step 1:${NC} Edit your shell configuration file"
echo -e "  ${CYAN}vim ~/.zshrc${NC}   (or nano, code, etc.)"
echo ""
echo -e "${YELLOW}Step 2:${NC} Add your credentials (choose the ones you have):"
echo ""
echo -e "  ${BLUE}# For Z.ai (if you have access):${NC}"
echo -e "  ${CYAN}export CLAUDE_ZAI_AUTH_TOKEN=\"your-zai-token-here\"${NC}"
echo -e "  ${CYAN}export CLAUDE_ZAI_BASE_URL=\"https://api.z.ai/api/anthropic\"${NC}"
echo ""
echo -e "  ${BLUE}# For MiniMax (if you have access):${NC}"
echo -e "  ${CYAN}export CLAUDE_MINIMAX_AUTH_TOKEN=\"your-minimax-token-here\"${NC}"
echo -e "  ${CYAN}export CLAUDE_MINIMAX_BASE_URL=\"https://api.minimax.io/anthropic\"${NC}"
echo ""
echo -e "  ${BLUE}# Your standard Anthropic token should already be in ~/.claude/settings.json${NC}"
echo ""
echo -e "${YELLOW}Step 3:${NC} Reload your shell"
echo -e "  ${CYAN}source ~/.zshrc${NC}"
echo ""
echo -e "${YELLOW}Step 4:${NC} Test the tool"
echo -e "  ${CYAN}claude-swap status${NC}"
echo ""
echo -e "${BLUE}Usage:${NC}"
echo -e "  ${YELLOW}claude-swap zai${NC}       - Switch to Z.ai"
echo -e "  ${YELLOW}claude-swap minimax${NC}   - Switch to MiniMax"
echo -e "  ${YELLOW}claude-swap standard${NC}  - Switch to standard Anthropic"
echo -e "  ${YELLOW}claude-swap status${NC}    - Check current config"
echo ""
echo -e "${GREEN}For help:${NC} ${CYAN}claude-swap help${NC}"
echo ""
echo -e "${BLUE}See example configurations:${NC}"
echo -e "  ${CYAN}/opt/homebrew/share/doc/claude-swap/example-configs.md${NC}"
echo ""
