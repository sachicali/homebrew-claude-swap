#!/usr/bin/env bash

# Instance Manager - Provider Isolation
# Single Responsibility: Manage isolated Claude instances per provider
# Inspired by CCS's instance isolation architecture

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# Instance base directory
readonly INSTANCE_BASE_DIR="$HOME/.claude/instances"

# Get instance directory for a provider
get_instance_dir() {
    local provider="${1:-}"

    if [[ -z "$provider" ]]; then
        log_error "Provider name required"
        return 1
    fi

    # Validate provider
    case "$provider" in
        standard|zai|kimi|kimi-for-coding|minimax|moonshot) ;;
        *)
            log_error "Invalid provider: $provider"
            return 1
            ;;
    esac

    # Normalize moonshot to kimi (but keep kimi-for-coding separate)
    [[ "$provider" == "moonshot" ]] && provider="kimi"

    echo "$INSTANCE_BASE_DIR/$provider"
}

# Initialize instance directory for a provider
init_instance() {
    local provider="${1:-}"
    local instance_dir

    instance_dir=$(get_instance_dir "$provider") || return 1

    # Create instance directory structure
    # NASA Rule 7: Check all return values
    if ! mkdir -p "$instance_dir" "$instance_dir/todos" "$instance_dir/projects" \
                   "$instance_dir/backups" "$instance_dir/session_backups"; then
        log_error "Failed to create instance directories for $provider"
        return 1
    fi

    # Create settings.json if it doesn't exist
    if [[ ! -f "$instance_dir/settings.json" ]]; then
        cat > "$instance_dir/settings.json" <<EOF
{
  "provider": "$provider",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "env": {}
}
EOF
    fi

    log_info "Initialized instance directory: $instance_dir"
    return 0
}

# Switch to a provider instance by setting CLAUDE_CONFIG_DIR
activate_instance() {
    local provider="${1:-}"
    local instance_dir

    instance_dir=$(get_instance_dir "$provider") || return 1

    # Initialize if doesn't exist
    if [[ ! -d "$instance_dir" ]]; then
        init_instance "$provider" || return 1
    fi

    # Export CLAUDE_CONFIG_DIR to switch instance
    export CLAUDE_CONFIG_DIR="$instance_dir"

    log_info "Activated instance: $provider ($instance_dir)"
    return 0
}

# List all provider instances
list_instances() {
    if [[ ! -d "$INSTANCE_BASE_DIR" ]]; then
        echo "No instances found"
        return 0
    fi

    local -a instances=()

    # Find instance directories (NASA Rule 2: Fixed bound)
    local count=0
    for dir in "$INSTANCE_BASE_DIR"/*; do
        if [[ $count -ge $MAX_INSTANCES_LIST ]]; then
            break
        fi

        if [[ -d "$dir" ]]; then
            local provider=$(basename "$dir")
            local status="inactive"

            # Check if currently active
            if [[ "${CLAUDE_CONFIG_DIR:-}" == "$dir" ]]; then
                status="active"
            fi

            # Check if configured
            local configured="○"
            case "$provider" in
                standard)
                    [[ -n "${ANTHROPIC_API_KEY:-}" ]] && configured="✓"
                    ;;
                zai)
                    [[ -n "${ZAI_AUTH_TOKEN:-}" ]] && configured="✓"
                    ;;
                kimi|kimi-for-coding)
                    [[ -n "${KIMI_AUTH_TOKEN:-}" ]] && configured="✓"
                    ;;
                minimax)
                    [[ -n "${MINIMAX_AUTH_TOKEN:-}" ]] && configured="✓"
                    ;;
            esac

            # Count sessions
            local session_count=0
            if [[ -d "$dir/todos" ]]; then
                session_count=$(find "$dir/todos" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
            fi

            instances+=("$provider|$status|$configured|$session_count")
            count=$((count + 1))
        fi
    done

    # Display as table
    if [[ ${#instances[@]} -gt 0 ]]; then
        echo "Provider|Status|Configured|Sessions"
        printf '%s\n' "${instances[@]}"
    else
        echo "No instances found"
    fi
}

# Get current active instance
get_active_instance() {
    if [[ -n "${CLAUDE_CONFIG_DIR:-}" ]]; then
        basename "$CLAUDE_CONFIG_DIR"
    else
        # Check traditional settings.json
        if [[ -f "$HOME/.claude/settings.json" ]]; then
            jq -r '.provider // "unknown"' "$HOME/.claude/settings.json" 2>/dev/null || echo "unknown"
        else
            echo "none"
        fi
    fi
}

# Clean up old instances
cleanup_instances() {
    local retention_days="${1:-90}"  # Default 90 days

    if [[ ! -d "$INSTANCE_BASE_DIR" ]]; then
        return 0
    fi

    log_info "Cleaning up instances older than $retention_days days..."

    local count=0

    for dir in "$INSTANCE_BASE_DIR"/*; do
        if [[ $count -ge $MAX_INSTANCES_CLEANUP ]]; then
            break
        fi

        if [[ -d "$dir" ]]; then
            # Check last modification time
            local mod_time
            mod_time=$(stat -f %m "$dir" 2>/dev/null || stat -c %Y "$dir" 2>/dev/null || echo 0)
            local current_time=$(date +%s)
            local age_days=$(( (current_time - mod_time) / SECONDS_PER_DAY ))

            if [[ $age_days -gt $retention_days ]]; then
                local provider=$(basename "$dir")
                log_warning "Removing old instance: $provider (${age_days} days old)"
                # NASA Rule 7: Check return value for destructive operations
                if ! rm -rf "$dir"; then
                    log_error "Failed to remove instance directory: $dir"
                    # Continue to next item instead of failing completely
                    continue
                fi
            fi
        fi

        count=$((count + 1))
    done

    log_success "Cleanup complete"
}

# Export instance settings as environment variables
export_instance_env() {
    local provider="${1:-}"
    local instance_dir

    instance_dir=$(get_instance_dir "$provider") || return 1

    if [[ ! -f "$instance_dir/settings.json" ]]; then
        log_error "Instance settings not found: $instance_dir/settings.json"
        return 1
    fi

    # Export CLAUDE_CONFIG_DIR
    export CLAUDE_CONFIG_DIR="$instance_dir"

    # Update symlink for backward compatibility
    if [[ -L "$HOME/.claude/current" ]]; then
        rm "$HOME/.claude/current"
    fi
    ln -sf "$instance_dir" "$HOME/.claude/current"

    log_info "Instance environment exported for: $provider"
    return 0
}
