#!/usr/bin/env bash

# Session management utilities
# Single Responsibility: Handle session backup, restore, and compatibility

# Source guard
[[ -n "${_SESSIONS_LOADED:-}" ]] && return 0
readonly _SESSIONS_LOADED=1

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# Note: constants.sh, cache.sh, and logging.sh are sourced by the main claudeswap script

# Create backup directory if it doesn't exist
# NASA Rule 7: Check return values
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        if ! mkdir -p "$BACKUP_DIR"; then
            log_error "Failed to create backup directory: $BACKUP_DIR"
            return 1
        fi
        log_info "Created backup directory: $BACKUP_DIR"
    fi
    return 0
}

# Create session backup directory
# NASA Rule 7: Check return values
create_session_backup_dir() {
    if [[ ! -d "$CLAUDE_SESSION_BACKUP_DIR" ]]; then
        if ! mkdir -p "$CLAUDE_SESSION_BACKUP_DIR"; then
            log_error "Failed to create session backup directory: $CLAUDE_SESSION_BACKUP_DIR"
            return 1
        fi
    fi
    return 0
}

# Backup current sessions
# NASA Rule 7: Check return values
backup_sessions() {
    local backup_name="session_backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$CLAUDE_SESSION_BACKUP_DIR/$backup_name"

    if [[ -d "$CLAUDE_SESSION_DIR" ]] && [[ "$(ls -A "$CLAUDE_SESSION_DIR" 2>/dev/null)" ]]; then
        if ! cp -r "$CLAUDE_SESSION_DIR" "$backup_path"; then
            log_error "Failed to backup sessions"
            echo ""
            return 1
        fi
        log_success "Sessions backed up to: $backup_path"
        echo "$backup_path"
        return 0
    else
        log_info "No sessions to backup"
        echo ""
        return 0
    fi
}

# Clear all sessions
# NASA Rule 7: Check return values
# NASA Rule 2: Fixed loop bound
clear_sessions() {
    if [[ -d "$CLAUDE_SESSION_DIR" ]]; then
        local session_count=$(ls -1 "$CLAUDE_SESSION_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$session_count" -gt 0 ]]; then
            # NASA Rule 2: Verify session count is within reasonable bounds
            if [[ "$session_count" -gt "$MAX_SESSIONS_CLEANUP" ]]; then
                log_error "Session count exceeds safety limit ($MAX_SESSIONS_CLEANUP)"
                return 1
            fi
            if ! rm -f "$CLAUDE_SESSION_DIR"/*.json; then
                log_error "Failed to clear session files"
                return 1
            fi
            log_success "Cleared $session_count session files"
            return 0
        else
            log_info "No sessions to clear"
            return 0
        fi
    fi
    return 0
}

# Check if session is compatible between providers
is_session_compatible() {
    local from_provider="$1"
    local to_provider="$2"

    # Same provider is always compatible
    if [[ "$from_provider" == "$to_provider" ]]; then
        return 0
    fi

    # Z.ai and MiniMax are compatible (both proxy providers)
    if [[ "$from_provider" == "zai" && "$to_provider" == "minimax" ]] || \
       [[ "$from_provider" == "minimax" && "$to_provider" == "zai" ]]; then
        return 0
    fi

    # Standard with others is not compatible due to thinking blocks
    if [[ "$from_provider" == "standard" && "$to_provider" != "standard" ]] || \
       [[ "$to_provider" == "standard" && "$from_provider" != "standard" ]]; then
        return 1
    fi

    return 0
}
