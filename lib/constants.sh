#!/usr/bin/env bash

# Constants and configuration
# Single Responsibility: Define all constants and paths

# Source guard
[[ -n "${_CONSTANTS_LOADED:-}" ]] && return 0
readonly _CONSTANTS_LOADED=1

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

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

# Kimi/Moonshot Configuration
readonly KIMI_BASE_URL_DEFAULT="https://api.moonshot.cn/v1"
readonly KIMI_TIMEOUT_DEFAULT="3000000"
readonly KIMI_TEMP_MULTIPLIER="0.6"  # Kimi requires temp * 0.6

# Kimi for Coding Configuration (Official Moonshot Coding Plan)
readonly KIMI_FOR_CODING_BASE_URL_DEFAULT="https://api.kimi.com/coding/"
readonly KIMI_FOR_CODING_MODEL="kimi-for-coding"
readonly KIMI_FOR_CODING_TIMEOUT_DEFAULT="3000000"

# Standard Configuration
readonly STANDARD_TIMEOUT_DEFAULT="120000"

# API Timeouts (for curl operations)
readonly OPENROUTER_TIMEOUT="15"
readonly PROVIDER_API_TIMEOUT="10"
readonly MODEL_LINE_LIMIT="500"
readonly MAX_MODELS_PER_PROVIDER="100"

# Environment variables (with fallbacks)
# NOTE: These are NOT readonly because they get exported/reassigned in setup functions
ZAI_BASE_URL="${CLAUDE_ZAI_BASE_URL:-$ZAI_BASE_URL_DEFAULT}"
ZAI_AUTH_TOKEN="${CLAUDE_ZAI_AUTH_TOKEN:-}"
ZAI_TIMEOUT="${CLAUDE_ZAI_TIMEOUT:-$ZAI_TIMEOUT_DEFAULT}"

MINIMAX_BASE_URL="${CLAUDE_MINIMAX_BASE_URL:-$MINIMAX_BASE_URL_DEFAULT}"
MINIMAX_AUTH_TOKEN="${CLAUDE_MINIMAX_AUTH_TOKEN:-}"
MINIMAX_TIMEOUT="${CLAUDE_MINIMAX_TIMEOUT:-$MINIMAX_TIMEOUT_DEFAULT}"

KIMI_BASE_URL="${CLAUDE_KIMI_BASE_URL:-$KIMI_BASE_URL_DEFAULT}"
KIMI_AUTH_TOKEN="${CLAUDE_KIMI_AUTH_TOKEN:-}"
KIMI_TIMEOUT="${CLAUDE_KIMI_TIMEOUT:-$KIMI_TIMEOUT_DEFAULT}"

# Kimi for Coding uses same auth token but different base URL
KIMI_FOR_CODING_BASE_URL="${CLAUDE_KIMI_FOR_CODING_BASE_URL:-$KIMI_FOR_CODING_BASE_URL_DEFAULT}"
KIMI_FOR_CODING_AUTH_TOKEN="${CLAUDE_KIMI_AUTH_TOKEN:-}"  # Same token as regular Kimi
KIMI_FOR_CODING_TIMEOUT="${CLAUDE_KIMI_FOR_CODING_TIMEOUT:-$KIMI_FOR_CODING_TIMEOUT_DEFAULT}"

STANDARD_TIMEOUT="${CLAUDE_STANDARD_TIMEOUT:-$STANDARD_TIMEOUT_DEFAULT}"

# TUI Configuration
readonly HISTORY_DB="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/history.db"
readonly TUI_MODE="${CLAUDESWAP_TUI_MODE:-auto}"  # auto, always, never
readonly GUM_REQUIRED_VERSION="0.13.0"

# Gum Styling
readonly GUM_CHOOSE_HEIGHT="10"
readonly GUM_FILTER_HEIGHT="15"
readonly GUM_BORDER_STYLE="rounded"
readonly GUM_PRIMARY_COLOR="#00BFFF"
readonly GUM_SUCCESS_COLOR="#00FF00"
readonly GUM_ERROR_COLOR="#FF0000"
readonly GUM_WARNING_COLOR="#FFFF00"

# TUI Limits (NASA Rule 2)
readonly MAX_HISTORY_ENTRIES=1000
readonly MAX_MENU_ITEMS=50
readonly HISTORY_RETENTION_DAYS=90

# Instance Manager Limits
readonly MAX_INSTANCES_LIST=20
readonly MAX_INSTANCES_CLEANUP=50

# Session Management Limits
readonly MAX_SESSIONS_CLEANUP=10000

# TUI Component Limits
readonly MAX_TUI_MENU_ITEMS=8
readonly MAX_TUI_ITERATIONS=1000
readonly MAX_PROVIDERS_DISPLAY=10
readonly MAX_MODELS_DISPLAY=200

# Provider Model Fetching Limits
readonly MAX_UNIQUE_MODELS=200
readonly MAX_FETCH_MODELS=500
readonly MAX_FETCH_LINES=500
readonly MAX_PROVIDER_PARSE_LINES=100

# Formatting and Display Constants
readonly TUI_INPUT_WIDTH=60
readonly CONTEXT_MB_DIVISOR=1000000
readonly CONTEXT_KB_DIVISOR=1000

# Time Constants
readonly SECONDS_PER_DAY=86400
