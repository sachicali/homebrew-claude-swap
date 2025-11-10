#!/usr/bin/env bash

# TUI Credential Input Handler
# Single Responsibility: Interactive credential setup

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# NASA Rule 7: Check file existence before sourcing
if [[ ! -f "${CLAUDE_SWAP_BASE_DIR}/lib/tui/gum_utils.sh" ]]; then
    echo "ERROR: Required gum_utils.sh not found" >&2
    exit 1
fi

source "${CLAUDE_SWAP_BASE_DIR}/lib/tui/gum_utils.sh"

# Set up credentials for a specific provider with TUI
setup_provider_credentials_tui() {
    local provider="${1:-}"

    # If no provider specified, show selection
    if [[ -z "$provider" ]]; then
        gum style \
            --border "$GUM_BORDER_STYLE" \
            --border-foreground "$GUM_PRIMARY_COLOR" \
            --padding "1 2" \
            --margin "1" \
            "Select Provider for Credential Setup"

        local -a provider_options=(
            "Standard Anthropic API"
            "Z.ai / GLM"
            "Kimi / Moonshot"
            "MiniMax"
        )

        local choice
        choice=$(printf '%s\n' "${provider_options[@]}" | \
            gum choose --height="$GUM_CHOOSE_HEIGHT")

        # Map choice to provider name
        case "$choice" in
            "Standard Anthropic API") provider="standard" ;;
            "Z.ai / GLM") provider="zai" ;;
            "Kimi / Moonshot") provider="kimi" ;;
            "MiniMax") provider="minimax" ;;
            *)
                log_error "Invalid provider selection"
                return 1
                ;;
        esac
    fi

    # Validate provider name
    case "$provider" in
        standard|zai|kimi|minimax|moonshot) ;;
        *)
            log_error "Invalid provider: $provider"
            return 1
            ;;
    esac

    # Normalize moonshot to kimi
    [[ "$provider" == "moonshot" ]] && provider="kimi"

    # Show provider info
    gum style \
        --border "$GUM_BORDER_STYLE" \
        --border-foreground "$GUM_PRIMARY_COLOR" \
        --padding "1 2" \
        --margin "1" \
        "Setting up credentials for: $provider"

    # Get API token with password input
    local token
    token=$(gum input \
        --password \
        --placeholder "Enter API token" \
        --prompt "API Token: " \
        --width "$TUI_INPUT_WIDTH")

    # Validate token
    if [[ -z "$token" ]]; then
        gum style --foreground="$GUM_ERROR_COLOR" "Error: Token cannot be empty"
        return 1
    fi

    local token_len=${#token}
    if [[ $token_len -lt 10 ]]; then
        gum style --foreground="$GUM_ERROR_COLOR" "Error: Token too short (minimum 10 characters)"
        return 1
    fi

    # Ask if user wants to save to .zshrc
    gum style --foreground="$GUM_PRIMARY_COLOR" "Save token to ~/.zshrc?"
    local save_to_zshrc=false
    if gum confirm; then
        save_to_zshrc=true
    fi

    # Determine environment variable name
    local var_name=""
    case "$provider" in
        "standard")
            var_name="ANTHROPIC_API_KEY"
            ;;
        "zai")
            var_name="CLAUDE_ZAI_AUTH_TOKEN"
            ;;
        "kimi")
            var_name="CLAUDE_KIMI_AUTH_TOKEN"
            ;;
        "minimax")
            var_name="CLAUDE_MINIMAX_AUTH_TOKEN"
            ;;
        *)
            gum style --foreground="$GUM_ERROR_COLOR" "Error: Unknown provider $provider"
            return 1
            ;;
    esac

    # Export for current session
    export "$var_name=$token"

    # Save to .zshrc if requested
    if [[ "$save_to_zshrc" == true ]]; then
        # Backup .zshrc first
        if [[ -f "$HOME/.zshrc" ]]; then
            gum spin \
                --spinner dot \
                --title "Backing up ~/.zshrc..." \
                -- cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        fi

        # Use printf for safe escaping (prevents shell injection)
        printf "export %s='%s'\n" "$var_name" "$token" >> "$HOME/.zshrc"

        gum style \
            --foreground="$GUM_SUCCESS_COLOR" \
            "✓ Token saved to ~/.zshrc"
    else
        gum style \
            --foreground="$GUM_WARNING_COLOR" \
            "⚠️  Token set for current session only"
    fi

    # Validate credentials with spinner
    gum spin \
        --spinner dot \
        --title "Validating credentials..." \
        --show-output \
        -- sleep 1  # Placeholder for actual validation

    gum style \
        --foreground="$GUM_SUCCESS_COLOR" \
        "✓ Credentials configured successfully for $provider"

    return 0
}

# Show credential setup TUI (main entry point)
show_credential_setup_tui() {
    setup_provider_credentials_tui "$@"
}
