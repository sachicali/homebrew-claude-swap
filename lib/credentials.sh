#!/usr/bin/env bash

# Credential validation and setup
# Single Responsibility: Handle all credential-related operations

# Note: constants.sh and logging.sh are sourced by the main claudeswap script

# Interactive credential setup for a specific service
setup_service_credentials() {
    local service="$1"
    local var_name="$2"
    local url="$3"

    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                                                  ║${NC}"
    echo -e "${YELLOW}║     $service Setup Required                   ║${NC}"
    echo -e "${YELLOW}║                                                  ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}To get your $service API token:${NC}"
    echo -e "  1. Visit: ${CYAN}$url${NC}"
    echo -e "  2. Sign in or create an account"
    echo -e "  3. Navigate to API key management"
    echo -e "  4. Create a new API key"
    echo -e "  5. Copy the token"
    echo ""
    echo -e "${GREEN}Please paste your $service API token below:${NC}"
    echo -e "(Press ${CYAN}Ctrl+D${NC} when done, or ${CYAN}Enter${NC} then ${CYAN}Ctrl+D${NC} on a new line)"
    echo ""

    # Read token interactively
    local token
    IFS= read -r token

    if [[ -z "$token" ]]; then
        log_error "No token provided. Setup cancelled."
        return 1
    fi

    # Show the token (partially masked)
    local masked_token="${token:0:10}...${token: -4}"
    echo ""
    echo -e "${GREEN}✓${NC} Received token: ${masked_token}"
    echo ""

    # Ask if user wants to save to shell config
    echo -e "${YELLOW}Would you like to save this to your shell config? (y/n)${NC}"
    echo -e "This will add it to ${CYAN}$HOME/.zshrc${NC} (recommended)"
    echo ""
    printf "Save to ~/.zshrc? (y/n) "
    read -r reply
    echo ""

    if [[ $reply =~ ^[Yy]$ ]]; then
        # Create backup
        cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

        # Add to zshrc
        echo "" >> ~/.zshrc
        echo "# $service API Token - Added by claudeswap" >> ~/.zshrc
        echo "export $var_name=\"$token\"" >> ~/.zshrc

        echo -e "${GREEN}✓${NC} Token saved to ~/.zshrc"
        echo ""
        echo -e "${YELLOW}Important:${NC} Run ${CYAN}source ~/.zshrc${NC} or restart your terminal"
        echo ""

        # Set for current session
        export "$var_name"="$token"
    else
        echo -e "${YELLOW}Note:${NC} Token is set for this session only."
        echo -e "To use it permanently, add this to your ~/.zshrc:"
        echo -e "${CYAN}export $var_name=\"$token\"${NC}"
        echo ""
        export "$var_name"="$token"
    fi

    return 0
}

# Main interactive setup - choose provider
setup_credentials_interactive() {
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║     Claude Swap Interactive Setup              ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Choose a provider to configure:"
    echo "  1. Z.ai (GLM models: glm-4.6, glm-4.5)"
    echo "  2. MiniMax (MiniMax-M2, MiniMax-M1)"
    echo "  3. Standard Anthropic (claude-sonnet, claude-haiku)"
    echo ""

    while true; do
        printf "Select provider (1-3): "
        read -r choice

        case "$choice" in
            1)
                setup_service_credentials "Z.ai" "CLAUDE_ZAI_AUTH_TOKEN" "https://z.ai/manage-apikey/apikey-list"
                # Ask for model selection if token was set
                if [[ -n "${CLAUDE_ZAI_AUTH_TOKEN:-}" ]]; then
                    echo ""
                    echo "Would you like to select a specific GLM model?"
                    printf "Select model now? (y/n) "
                    read -r select_model
                    if [[ $select_model =~ ^[Yy]$ ]]; then
                        local zai_model=$(select_model_interactive "zai")
                        if [[ -n "$zai_model" ]]; then
                            log_info "Model selection completed. You can verify with: claudeswap status"
                        fi
                    fi
                fi
                break
                ;;
            2)
                setup_service_credentials "MiniMax" "CLAUDE_MINIMAX_AUTH_TOKEN" "https://platform.minimax.io/user-center/basic-information/interface-key"
                # Ask for model selection if token was set
                if [[ -n "${CLAUDE_MINIMAX_AUTH_TOKEN:-}" ]]; then
                    echo ""
                    echo "Would you like to select a specific MiniMax model?"
                    printf "Select model now? (y/n) "
                    read -r select_model
                    if [[ $select_model =~ ^[Yy]$ ]]; then
                        local minimax_model=$(select_model_interactive "minimax")
                        if [[ -n "$minimax_model" ]]; then
                            log_info "Model selection completed. You can verify with: claudeswap status"
                        fi
                    fi
                fi
                break
                ;;
            3)
                log_info "Standard Anthropic API doesn't require setup"
                echo ""
                echo "Simply ensure you have an Anthropic API key in:"
                echo "  - Environment variable: ANTHROPIC_API_KEY"
                echo "  - Claude Desktop settings"
                echo ""
                break
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, or 3"
                ;;
        esac
    done

    echo ""
    echo -e "${GREEN}✓ Setup complete!${NC}"
    echo ""
    echo "You can now use:"
    echo "  claudeswap status          - Check current configuration"
    echo "  claudeswap test-models     - View available models"
    echo "  claudeswap set <provider>  - Switch providers"
    echo ""
}

# Interactive model selection
select_model_interactive() {
    local provider="$1"
    local available_models=($(fetch_available_models "$provider"))

    if [[ ${#available_models[@]} -eq 0 ]]; then
        log_error "No models available for provider: $provider"
        return 1
    fi

    # Display models (without color codes for clean output)
    echo "" >&2
    echo "Available models for $provider:" >&2
    for i in "${!available_models[@]}"; do
        local model="${available_models[i]}"
        local details=$(get_model_details "$model" "$provider")
        printf "  %2d. %s%s\n" $((i+1)) "$model" "$details" >&2
    done

    while true; do
        echo "" >&2
        printf "Select model (1-${#available_models[@]}) or press Enter for default: " >&2
        read -r choice

        if [[ -z "$choice" ]]; then
            # Default selection
            case "$provider" in
                "standard") echo "claude-sonnet-4-5-20250929" ;;
                "minimax") echo "MiniMax-M2" ;;
                "zai"|"glm") echo "glm-4.6" ;;
            esac
            return 0
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#available_models[@]} ]]; then
            local selected_model="${available_models[$((choice-1))]}"
            echo "$selected_model"
            return 0
        else
            echo "Invalid selection. Please enter a number between 1 and ${#available_models[@]}" >&2
        fi
    done
}

# Setup Anthropic credentials
setup_anthropic_credentials() {
    # No-op - handle_set() creates correct settings.json structure
    # Standard Anthropic credentials come from ANTHROPIC_API_KEY environment variable
    return 0
}

# Setup Z.ai credentials
setup_zai_credentials() {
    if [[ -z "$ZAI_AUTH_TOKEN" ]]; then
        log_error "Z.ai credentials not configured!"
        echo ""
        echo "To configure manually:"
        echo 'export CLAUDE_ZAI_AUTH_TOKEN="your-zai-token-here"'
        echo 'export CLAUDE_ZAI_BASE_URL="https://api.z.ai/api/anthropic"'
        echo ""
        echo "Or run: claudeswap setup"
        return 1
    fi

    # Set environment for Z.ai
    export ZAI_API_KEY="$ZAI_AUTH_TOKEN"
    export ZAI_BASE_URL="${ZAI_BASE_URL:-$ZAI_BASE_URL_DEFAULT}"
    export ZAI_TIMEOUT="${ZAI_TIMEOUT:-$ZAI_TIMEOUT_DEFAULT}"

    log_success "Z.ai credentials configured"
}

# Setup MiniMax credentials
setup_minimax_credentials() {
    if [[ -z "$MINIMAX_AUTH_TOKEN" ]]; then
        log_error "MiniMax credentials not configured!"
        echo ""
        echo "To configure manually:"
        echo 'export CLAUDE_MINIMAX_AUTH_TOKEN="your-minimax-token-here"'
        echo 'export CLAUDE_MINIMAX_BASE_URL="https://api.minimax.io/anthropic"'
        echo ""
        echo "Or run: claudeswap setup"
        return 1
    fi

    # Set environment for MiniMax
    export MINIMAX_API_KEY="$MINIMAX_AUTH_TOKEN"
    export MINIMAX_BASE_URL="${MINIMAX_BASE_URL:-$MINIMAX_BASE_URL_DEFAULT}"
    export MINIMAX_TIMEOUT="${MINIMAX_TIMEOUT:-$MINIMAX_TIMEOUT_DEFAULT}"

    log_success "MiniMax credentials configured"
}

# Validate credentials
validate_credentials() {
    local service="$1"
    local token="$2"

    if [[ -z "$token" ]] || [[ "$token" == "your-token-here" ]]; then
        log_error "$service credentials not configured!"
        echo ""

        # Offer interactive setup
        echo -e "${BLUE}Would you like to set up $service interactively? (y/n)${NC}"
        printf "Interactive setup? (y/n) "
        read -r reply
        echo ""

        if [[ $reply =~ ^[Yy]$ ]]; then
            if [[ "$service" == "Z.ai" ]]; then
                setup_service_credentials "Z.ai" "CLAUDE_ZAI_AUTH_TOKEN" "https://z.ai/manage-apikey/apikey-list"
            elif [[ "$service" == "MiniMax" ]]; then
                setup_service_credentials "MiniMax" "CLAUDE_MINIMAX_AUTH_TOKEN" "https://platform.minimax.io/user-center/basic-information/interface-key"
            fi
            # Refresh the token variable after interactive setup
            if [[ "$service" == "Z.ai" ]]; then
                token="${CLAUDE_ZAI_AUTH_TOKEN:-}"
            elif [[ "$service" == "MiniMax" ]]; then
                token="${CLAUDE_MINIMAX_AUTH_TOKEN:-}"
            fi

            # Check if still empty after interactive setup
            if [[ -z "$token" ]]; then
                log_error "Setup incomplete or cancelled."
                return 1
            fi
        else
            echo ""
            echo "To configure manually, set environment variables:"
            echo ""
            if [[ "$service" == "Z.ai" ]]; then
                echo "export CLAUDE_ZAI_AUTH_TOKEN=\"your-zai-token-here\""
                echo "export CLAUDE_ZAI_BASE_URL=\"https://api.z.ai/api/anthropic\""
                echo ""
                echo "Add these to your ~/.zshrc or ~/.bashrc"
            elif [[ "$service" == "MiniMax" ]]; then
                echo "export CLAUDE_MINIMAX_AUTH_TOKEN=\"your-minimax-token-here\""
                echo "export CLAUDE_MINIMAX_BASE_URL=\"https://api.minimax.io/anthropic\""
                echo ""
                echo "Add these to your ~/.zshrc or ~/.bashrc"
            fi
            echo ""
            echo "Or run this command again and choose interactive setup."
            return 1
        fi
    fi
    return 0
}
