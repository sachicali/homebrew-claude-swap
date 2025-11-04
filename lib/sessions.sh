#!/usr/bin/env bash

# Session management utilities
# Single Responsibility: Handle session backup, restore, and compatibility

# Note: constants.sh, cache.sh, and logging.sh are sourced by the main claudeswap script

# Create backup directory if it doesn't exist
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        log_info "Created backup directory: $BACKUP_DIR"
    fi
}

# Create session backup directory
create_session_backup_dir() {
    if [[ ! -d "$CLAUDE_SESSION_BACKUP_DIR" ]]; then
        mkdir -p "$CLAUDE_SESSION_BACKUP_DIR"
    fi
}

# Backup current sessions
backup_sessions() {
    local backup_name="session_backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$CLAUDE_SESSION_BACKUP_DIR/$backup_name"

    if [[ -d "$CLAUDE_SESSION_DIR" ]] && [[ "$(ls -A "$CLAUDE_SESSION_DIR" 2>/dev/null)" ]]; then
        cp -r "$CLAUDE_SESSION_DIR" "$backup_path"
        log_success "Sessions backed up to: $backup_path"
        echo "$backup_path"
    else
        log_info "No sessions to backup"
        echo ""
    fi
}

# Clear all sessions
clear_sessions() {
    if [[ -d "$CLAUDE_SESSION_DIR" ]]; then
        local session_count=$(ls -1 "$CLAUDE_SESSION_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$session_count" -gt 0 ]]; then
            rm -f "$CLAUDE_SESSION_DIR"/*.json
            log_success "Cleared $session_count session files"
        else
            log_info "No sessions to clear"
        fi
    fi
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
