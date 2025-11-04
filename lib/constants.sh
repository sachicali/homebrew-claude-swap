#!/usr/bin/env bash

# Constants and configuration
# Single Responsibility: Define all constants and paths

# Paths
readonly SETTINGS_FILE="$HOME/.claude/settings.json"
readonly BACKUP_DIR="$HOME/.claude/backups"
readonly CLAUDE_SESSION_DIR="$HOME/.claude/todos"
readonly CLAUDE_TODO_DIR="$HOME/.claude/todos"
readonly CLAUDE_PROJECT_DIR="$HOME/.claude/projects"
readonly CLAUDE_SESSION_BACKUP_DIR="$HOME/.claude/session_backups"
readonly CACHE_FILE_PREFIX="/tmp/claude_model_cache_"
readonly CACHE_SIZE_LIMIT=100

# Time
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Z.ai Configuration
readonly ZAI_BASE_URL_DEFAULT="https://api.z.ai/api/anthropic"
readonly ZAI_TIMEOUT_DEFAULT="3000000"

# MiniMax Configuration
readonly MINIMAX_BASE_URL_DEFAULT="https://api.minimax.io/anthropic"
readonly MINIMAX_TIMEOUT_DEFAULT="3000000"

# Standard Configuration
readonly STANDARD_TIMEOUT_DEFAULT="120000"

# Environment variables (with fallbacks)
ZAI_BASE_URL="${CLAUDE_ZAI_BASE_URL:-$ZAI_BASE_URL_DEFAULT}"
ZAI_AUTH_TOKEN="${CLAUDE_ZAI_AUTH_TOKEN:-}"
ZAI_TIMEOUT="${CLAUDE_ZAI_TIMEOUT:-$ZAI_TIMEOUT_DEFAULT}"

MINIMAX_BASE_URL="${CLAUDE_MINIMAX_BASE_URL:-$MINIMAX_BASE_URL_DEFAULT}"
MINIMAX_AUTH_TOKEN="${CLAUDE_MINIMAX_AUTH_TOKEN:-}"
MINIMAX_TIMEOUT="${CLAUDE_MINIMAX_TIMEOUT:-$MINIMAX_TIMEOUT_DEFAULT}"

STANDARD_TIMEOUT="${CLAUDE_STANDARD_TIMEOUT:-$STANDARD_TIMEOUT_DEFAULT}"
