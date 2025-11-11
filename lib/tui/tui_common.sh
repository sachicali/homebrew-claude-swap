#!/usr/bin/env bash

# TUI Common Library
# Single Responsibility: Provide shared dependencies and functions for all TUI components
# This file ensures all TUI components have access to required constants, functions, and utilities

# Source guard
[[ -n "${_TUI_COMMON_LOADED:-}" ]] && return 0
readonly _TUI_COMMON_LOADED=1

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# Validate CLAUDE_SWAP_BASE_DIR is set
if [[ -z "${CLAUDE_SWAP_BASE_DIR:-}" ]]; then
    echo "ERROR: CLAUDE_SWAP_BASE_DIR not set" >&2
    exit 1
fi

# Source core dependencies in correct order
# NASA Rule 7: Check file existence before sourcing
_source_if_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "ERROR: Required file not found: $file" >&2
        return 1
    fi
    source "$file"
}

# Core libraries (required)
_source_if_exists "${CLAUDE_SWAP_BASE_DIR}/lib/constants.sh" || exit 1
_source_if_exists "${CLAUDE_SWAP_BASE_DIR}/lib/logging.sh" || exit 1
_source_if_exists "${CLAUDE_SWAP_BASE_DIR}/lib/utils/cache.sh" || exit 1
_source_if_exists "${CLAUDE_SWAP_BASE_DIR}/lib/utils/formatter.sh" || exit 1
_source_if_exists "${CLAUDE_SWAP_BASE_DIR}/lib/models.sh" || exit 1
_source_if_exists "${CLAUDE_SWAP_BASE_DIR}/lib/sessions.sh" || exit 1
_source_if_exists "${CLAUDE_SWAP_BASE_DIR}/lib/providers/model_fetch.sh" || exit 1
_source_if_exists "${CLAUDE_SWAP_BASE_DIR}/lib/credentials.sh" || exit 1
_source_if_exists "${CLAUDE_SWAP_BASE_DIR}/lib/instance_manager.sh" || exit 1

# TUI-specific library
_source_if_exists "${CLAUDE_SWAP_BASE_DIR}/lib/tui/gum_utils.sh" || exit 1

# Check for required commands
check_jq_available() {
    if ! command -v jq &>/dev/null; then
        log_error "jq is required but not installed. Please install jq to use this feature."
        log_error "Installation: brew install jq (macOS) or apt-get install jq (Linux)"
        return 1
    fi
    return 0
}

# Wrapper and helper functions for TUI components
# These allow TUI components to access functionality from the main script and libraries

# Get current provider from settings
get_current_provider() {
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        echo "unknown"
        return 0
    fi

    # Check jq availability before using it
    if ! check_jq_available; then
        echo "unknown"
        return 0  # Return success to allow graceful degradation
    fi

    local provider
    provider=$(jq -r '.provider // "unknown"' "$SETTINGS_FILE" 2>/dev/null || echo "unknown")
    echo "$provider"
}

# Check if provider is configured
is_provider_configured() {
    local provider="$1"

    case "$provider" in
        "standard")
            [[ -n "${ANTHROPIC_API_KEY:-}" ]] && return 0
            ;;
        "zai")
            # Check both variable names for compatibility
            [[ -n "${ZAI_AUTH_TOKEN:-}" ]] || [[ -n "${ZAI_API_KEY:-}" ]] && return 0
            ;;
        "minimax")
            # Check both variable names for compatibility
            [[ -n "${MINIMAX_AUTH_TOKEN:-}" ]] || [[ -n "${MINIMAX_API_KEY:-}" ]] && return 0
            ;;
        "kimi"|"moonshot"|"kimi-for-coding")
            # Check both variable names for compatibility
            [[ -n "${KIMI_AUTH_TOKEN:-}" ]] || [[ -n "${KIMI_API_KEY:-}" ]] && return 0
            ;;
    esac

    return 1
}

# Wrapper for handle_set (defined in main script)
# This will be called by provider_select.sh
tui_handle_set() {
    local provider="$1"
    local model="${2:-}"

    # Call the main script's handle_set if it exists
    if declare -f handle_set >/dev/null 2>&1; then
        handle_set "$provider" "$model"
    else
        log_error "handle_set function not available"
        return 1
    fi
}

# Wrapper for handle_status (defined in main script)
tui_handle_status() {
    # Call the main script's handle_status if it exists
    if declare -f handle_status >/dev/null 2>&1; then
        handle_status
    else
        log_error "handle_status function not available"
        return 1
    fi
}

# Export all required functions for TUI components
export -f get_current_provider
export -f is_provider_configured
export -f tui_handle_set
export -f tui_handle_status
