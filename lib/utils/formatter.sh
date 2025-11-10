#!/usr/bin/env bash

# Formatter utilities
# Single Responsibility: Format data for display

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# Format context length in human-readable form
# NASA Rule 7: Validate input parameter
format_context_length() {
    local context_length="${1:-}"

    if [[ -z "$context_length" ]] || [[ "$context_length" == "null" ]]; then
        return
    fi

    # Format context length in human-readable form (portable alternative to numfmt)
    local context_num="$context_length"
    if [[ "$context_length" -gt $CONTEXT_MB_DIVISOR ]]; then
        context_num="$(($context_length / $CONTEXT_MB_DIVISOR))M"
    elif [[ "$context_length" -gt $CONTEXT_KB_DIVISOR ]]; then
        context_num="$(($context_length / $CONTEXT_KB_DIVISOR))K"
    fi

    echo "Context: $context_num"
}

# Safe array check for zsh compatibility
safe_array_check() {
    local array_name="$1"
    # Check if array is empty or unset in zsh-compatible way
    if [[ -z "${!array_name:-}" ]]; then
        return 1  # Empty or unset
    fi
    return 0  # Has values
}
