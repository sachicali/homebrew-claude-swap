#!/usr/bin/env bash

# TUI Provider Selection Handler
# Single Responsibility: Interactive provider selection and switching

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# NASA Rule 7: Check file existence before sourcing
if [[ ! -f "${CLAUDE_SWAP_BASE_DIR}/lib/tui/gum_utils.sh" ]]; then
    echo "ERROR: Required gum_utils.sh not found" >&2
    exit 1
fi

source "${CLAUDE_SWAP_BASE_DIR}/lib/tui/gum_utils.sh"

# Get current provider from settings
get_current_provider_tui() {
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        echo "unknown"
        return 0
    fi

    local provider
    provider=$(jq -r '.provider // "unknown"' "$SETTINGS_FILE" 2>/dev/null || echo "unknown")
    echo "$provider"
}

# Check if provider credentials are configured
is_provider_configured() {
    local provider="$1"

    case "$provider" in
        "standard")
            [[ -n "${ANTHROPIC_API_KEY:-}" ]] && return 0 || return 1
            ;;
        "zai")
            # Check both variable names for compatibility
            [[ -n "${ZAI_AUTH_TOKEN:-}" ]] || [[ -n "${ZAI_API_KEY:-}" ]] && return 0 || return 1
            ;;
        "minimax")
            # Check both variable names for compatibility
            [[ -n "${MINIMAX_AUTH_TOKEN:-}" ]] || [[ -n "${MINIMAX_API_KEY:-}" ]] && return 0 || return 1
            ;;
        "kimi"|"moonshot"|"kimi-for-coding")
            # Check both variable names for compatibility
            [[ -n "${KIMI_AUTH_TOKEN:-}" ]] || [[ -n "${KIMI_API_KEY:-}" ]] && return 0 || return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# Show provider selection with status indicators
show_provider_selection_tui() {
    local current_provider
    current_provider=$(get_current_provider_tui)

    # Build provider list with status indicators
    local -a providers=()
    local -a provider_names=("standard" "zai" "kimi" "kimi-for-coding" "minimax")
    local -a display_names=(
        "Standard Anthropic API"
        "Z.ai / GLM"
        "Kimi / Moonshot (General)"
        "Kimi for Coding (Optimized)"
        "MiniMax"
    )

    # NASA Rule 2: Fixed bounds
    local provider_count=0

    for i in "${!provider_names[@]}"; do
        if [[ $provider_count -ge $MAX_PROVIDERS_DISPLAY ]]; then
            break
        fi

        local prov="${provider_names[$i]}"
        local display="${display_names[$i]}"
        local status_indicator=""

        # Check if configured
        if is_provider_configured "$prov"; then
            status_indicator="✓"
        else
            status_indicator="○"
        fi

        # Mark current provider
        if [[ "$prov" == "$current_provider" ]]; then
            display="$display ⭐ (current)"
        fi

        providers+=("$status_indicator $display")
        provider_count=$((provider_count + 1))
    done

    # Display styled header
    gum style \
        --border "$GUM_BORDER_STYLE" \
        --border-foreground "$GUM_PRIMARY_COLOR" \
        --padding "1 2" \
        --margin "1" \
        "Select Provider to Switch" \
        "" \
        "✓ = Configured | ○ = Not Configured"

    # Show filterable provider list
    local choice
    choice=$(printf '%s\n' "${providers[@]}" | \
        gum filter \
            --placeholder="Type to filter providers..." \
            --height="$GUM_FILTER_HEIGHT" \
            --indicator.foreground="$GUM_PRIMARY_COLOR")

    # Extract provider name from choice
    local selected_provider=""
    if [[ "$choice" == *"Standard Anthropic"* ]]; then
        selected_provider="standard"
    elif [[ "$choice" == *"Z.ai"* ]]; then
        selected_provider="zai"
    elif [[ "$choice" == *"Kimi for Coding"* ]]; then
        selected_provider="kimi-for-coding"
    elif [[ "$choice" == *"Kimi"* ]]; then
        selected_provider="kimi"
    elif [[ "$choice" == *"MiniMax"* ]]; then
        selected_provider="minimax"
    else
        log_error "Invalid provider selection"
        return 1
    fi

    # Check if credentials are configured
    if ! is_provider_configured "$selected_provider"; then
        gum style \
            --foreground="$GUM_WARNING_COLOR" \
            "⚠️  Provider not configured!"

        if gum confirm "Would you like to set up credentials now?"; then
            # Call credential setup for this provider
            if [[ -f "${CLAUDE_SWAP_BASE_DIR}/lib/tui/credential_input.sh" ]]; then
                source "${CLAUDE_SWAP_BASE_DIR}/lib/tui/credential_input.sh"
                setup_provider_credentials_tui "$selected_provider" || return 1
            else
                log_error "Credential setup not available"
                return 1
            fi
        else
            log_info "Cancelled provider switch"
            return 0
        fi
    fi

    # Confirm switch if different from current
    if [[ "$selected_provider" != "$current_provider" ]]; then
        gum style \
            --foreground="$GUM_PRIMARY_COLOR" \
            "Switch from $current_provider to $selected_provider?"

        if gum confirm; then
            # Perform the switch with spinner
            gum spin \
                --spinner dot \
                --title "Switching provider..." \
                --show-output \
                -- handle_set "$selected_provider"

            gum style \
                --foreground="$GUM_SUCCESS_COLOR" \
                "✓ Successfully switched to $selected_provider"
        else
            log_info "Cancelled provider switch"
        fi
    else
        gum style \
            --foreground="$GUM_PRIMARY_COLOR" \
            "Already using $selected_provider"
    fi

    return 0
}
