#!/usr/bin/env bash

# Logging utilities
# Single Responsibility: Provide colorized logging functions

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# Info log (stderr)
# NASA Rule 7: Validate parameter
log_info() {
    local message="${1:-}"
    if [[ -z "$message" ]]; then
        echo -e "${BLUE}[INFO]${NC} (empty message)" >&2
        return 0
    fi
    echo -e "${BLUE}[INFO]${NC} $message" >&2
}

# Success log (stderr)
# NASA Rule 7: Validate parameter
log_success() {
    local message="${1:-}"
    if [[ -z "$message" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} (empty message)" >&2
        return 0
    fi
    echo -e "${GREEN}[SUCCESS]${NC} $message" >&2
}

# Warning log (stderr)
# NASA Rule 7: Validate parameter
log_warning() {
    local message="${1:-}"
    if [[ -z "$message" ]]; then
        echo -e "${YELLOW}[WARNING]${NC} (empty message)" >&2
        return 0
    fi
    echo -e "${YELLOW}[WARNING]${NC} $message" >&2
}

# Error log (stderr)
# NASA Rule 7: Validate parameter
log_error() {
    local message="${1:-}"
    if [[ -z "$message" ]]; then
        echo -e "${RED}[ERROR]${NC} (empty message)" >&2
        return 0
    fi
    echo -e "${RED}[ERROR]${NC} $message" >&2
}

# TUI-aware logging functions (suppress raw messages during TUI operations)
# NASA Rule 7: Validate parameter
log_info_tui() {
    local message="${1:-}"
    if [[ -z "$message" ]]; then
        return 0
    fi
    # Only log if not in pure TUI mode (check if gum is available and we're interactive)
    if [[ -z "${GUM_INTERACTIVE:-}" ]] || [[ "$GUM_INTERACTIVE" != "true" ]]; then
        echo -e "${BLUE}[INFO]${NC} $message" >&2
    fi
}

# NASA Rule 7: Validate parameter
log_warning_tui() {
    local message="${1:-}"
    if [[ -z "$message" ]]; then
        return 0
    fi
    # Show warnings in TUI using gum style instead of raw text
    if [[ -n "${GUM_AVAILABLE:-}" ]] && command -v gum >/dev/null 2>&1; then
        gum style --foreground="$GUM_WARNING_COLOR" "Warning: $message" >&2
    else
        echo -e "${YELLOW}[WARNING]${NC} $message" >&2
    fi
}

# NASA Rule 7: Validate parameter
log_error_tui() {
    local message="${1:-}"
    if [[ -z "$message" ]]; then
        return 0
    fi
    # Show errors in TUI using gum style instead of raw text
    if [[ -n "${GUM_AVAILABLE:-}" ]] && command -v gum >/dev/null 2>&1; then
        gum style --foreground="$GUM_ERROR_COLOR" "Error: $message" >&2
        sleep 2  # Give user time to read
    else
        echo -e "${RED}[ERROR]${NC} $message" >&2
    fi
}
