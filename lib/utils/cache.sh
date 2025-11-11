#!/usr/bin/env bash

# Model cache utilities (file-based for zsh compatibility)
# Single Responsibility: Handle model extraction caching

# Source guard
[[ -n "${_CACHE_LOADED:-}" ]] && return 0
readonly _CACHE_LOADED=1

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# Note: constants.sh is sourced by the main claudeswap script

# Cache file path
CACHE_FILE="${CACHE_FILE_PREFIX}$$"

# Extract model from session for analysis with caching
extract_session_model() {
    local session_file="$1"
    local file_hash=$(stat -f "%m%z" "$session_file" 2>/dev/null || stat -c "%Y%s" "$session_file" 2>/dev/null || echo "0")

    # Check cache first
    local cache_key="${session_file}:${file_hash}"

    # Check file cache
    if [[ -f "$CACHE_FILE" ]]; then
        local cached_model=$(grep "^${cache_key}:" "$CACHE_FILE" 2>/dev/null | cut -d: -f2-)
        if [[ -n "$cached_model" ]]; then
            echo "$cached_model"
            return 0
        fi
    fi

    # Extract model (optimized - read only first few KB)
    local model="unknown"
    if [[ -f "$session_file" ]]; then
        # Read only first 8KB for speed (most models are in early messages)
        model=$(head -c 8192 "$session_file" 2>/dev/null | \
            grep '"type":"assistant"' | head -1 | \
            jq -r '.message.model // "unknown"' 2>/dev/null || echo "unknown")
    fi

    # Update file cache (with size management)
    echo "${cache_key}:${model}" >> "$CACHE_FILE" 2>/dev/null || true

    # Trim cache file if it gets too large
    # Security: Use mktemp for atomic operations
    local cache_lines=$(wc -l < "$CACHE_FILE" 2>/dev/null || echo 0)
    if [[ $cache_lines -gt $CACHE_SIZE_LIMIT ]]; then
        local temp_cache
        temp_cache=$(mktemp) || return 0
        trap "rm -f '$temp_cache'" EXIT

        if tail -n $((CACHE_SIZE_LIMIT / 2)) "$CACHE_FILE" > "$temp_cache" 2>/dev/null; then
            mv "$temp_cache" "$CACHE_FILE" 2>/dev/null || true
        fi

        # Clean up immediately if successful
        rm -f "$temp_cache" 2>/dev/null || true
    fi

    echo "$model"
}
