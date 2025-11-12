#!/usr/bin/env bash

# Credential validation and setup
# Single Responsibility: Handle all credential-related operations

# Source guard
[[ -n "${_CREDENTIALS_LOADED:-}" ]] && return 0
readonly _CREDENTIALS_LOADED=1

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# Note: constants.sh and logging.sh are sourced by the main claudeswap script

# NASA Rule 2: Maximum iterations for interactive loops
readonly MAX_INTERACTIVE_ATTEMPTS=50

# Detect shell and config file
detect_shell_config() {
    local shell_name
    shell_name=$(basename "$SHELL")

    case "$shell_name" in
        zsh)
            echo "$HOME/.zshrc"
            ;;
        bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "$HOME/.bashrc"
            else
                echo "$HOME/.bash_profile"
            fi
            ;;
        *)
            # Default to .bashrc
            echo "$HOME/.bashrc"
            ;;
    esac
}

# Validate shell variable name
validate_var_name() {
    local var_name="$1"

    # Variable name must start with letter or underscore, contain only alphanumeric and underscores
    if [[ ! "$var_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        return 1
    fi
    return 0
}

# Read password/token securely (with masking)
read_token_secure() {
    local prompt="$1"
    local token=""

    # Show prompt explicitly (read -p writes to stderr, so show it first)
    printf "%s" "$prompt" >&2

    # Try to use read -s for password masking (don't redirect stderr)
    if read -s token; then
        printf "\n" >&2  # New line after hidden input
        echo "$token"
    else
        # Fallback failed - password masking not available
        printf "\n" >&2
        log_error "Password masking not available on this system"
        echo ""
        echo -e "${RED}⚠️  SECURITY WARNING:${NC} Your input will be visible on screen!"
        echo -e "${YELLOW}Press Ctrl+C to abort, or Enter to continue at your own risk${NC}"
        read -p "Continue? (yes/no): " confirm
        if [[ ! "$confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
            log_info "Setup cancelled for security"
            return 1
        fi
        # Read without masking after explicit confirmation
        read -p "$prompt" token
        echo "$token"
    fi
}

# Interactive credential setup for a specific service
setup_service_credentials() {
    local service="$1"
    local var_name="$2"
    local url="$3"

    # Validate variable name for security
    if ! validate_var_name "$var_name"; then
        log_error "Invalid variable name: $var_name"
        return 1
    fi

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
    echo -e "${GREEN}Please enter your $service API token:${NC}"
    echo -e "${BLUE}(Input will be hidden for security)${NC}"
    echo ""

    # Read token securely with masking
    local token
    token=$(read_token_secure "Token: ")
    echo "" # New line after hidden input

    # Input validation: Check token
    if [[ -z "$token" ]]; then
        log_error "No token provided. Setup cancelled."
        return 1
    fi

    # Basic token validation: Check length and format
    local token_len=${#token}
    if [[ $token_len -lt 10 ]]; then
        log_error "Token too short (minimum 10 characters). Setup cancelled."
        return 1
    fi

    # Check for suspicious characters that might indicate input errors
    if [[ "$token" =~ [[:space:]] ]]; then
        log_warning "Token contains whitespace - this may be incorrect"
        printf "Continue anyway? (y/n) "
        read -r confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            log_info "Setup cancelled."
            return 1
        fi
    fi

    # Show the token (partially masked)
    # NASA Rule: Fix edge case for tokens < 14 characters
    local masked_token
    local token_length=${#token}
    if [[ $token_length -lt 14 ]]; then
        masked_token="${token:0:3}...${token: -2}"
    else
        masked_token="${token:0:10}...${token: -4}"
    fi
    echo ""
    echo -e "${GREEN}✓${NC} Received token: ${masked_token}"
    echo ""

    # Auto-detect shell config file
    local config_file
    config_file=$(detect_shell_config)

    # Ask if user wants to save to shell config
    echo -e "${YELLOW}Would you like to save this to your shell config? (y/n)${NC}"
    echo -e "This will add it to ${CYAN}$config_file${NC} (recommended)"
    echo ""
    printf "Save to $config_file? (y/n) "
    read -r reply
    echo ""

    if [[ $reply =~ ^[Yy]$ ]]; then
        # Create backup only if config file exists
        if [[ -f "$config_file" ]]; then
            local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
            if cp "$config_file" "$backup_file" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} Created backup: $backup_file"
            else
                log_warning "Failed to create backup, but continuing"
            fi
        else
            echo -e "${YELLOW}⚠${NC} Config file '$config_file' does not exist. Creating new file."
            touch "$config_file" || {
                log_error "Failed to create config file: $config_file"
                return 1
            }
        fi

        # Check for existing entry and update if present
        # Security: Use safer method to avoid shell injection
        # Use fixed-string grep and avoid sed with unescaped variables
        if grep -qF "export $var_name=" "$config_file" 2>/dev/null; then
            # Create temp file with updated content (safer than sed with special chars)
            local temp_file="${config_file}.tmp.$$"
            local updated=0

            # Preserve original file permissions
            local original_perms
            if [[ -f "$config_file" ]]; then
                original_perms=$(stat -c %a "$config_file" 2>/dev/null || stat -f %A "$config_file" 2>/dev/null || echo "644")
            else
                original_perms="644"
            fi

            while IFS= read -r line || [[ -n "$line" ]]; do
                # Check if this is the line to replace (using bash string matching, not regex)
                if [[ "$line" == "export $var_name="* ]]; then
                    printf "export %s='%s'\n" "$var_name" "$token"
                    updated=1
                else
                    printf "%s\n" "$line"
                fi
            done < "$config_file" > "$temp_file"

            # Set permissions on temp file before atomic move
            chmod "$original_perms" "$temp_file" 2>/dev/null || true

            # Replace original file with updated version (atomic operation)
            if [[ $updated -eq 1 ]] && mv -f "$temp_file" "$config_file"; then
                echo -e "${GREEN}✓${NC} Updated existing token in $config_file"
            else
                rm -f "$temp_file"
                log_error "Failed to update token in $config_file"
                return 1
            fi
        else
            # Add new entry
            {
                echo ""
                echo "# $service API Token - Added by claudeswap"
                printf "export %s='%s'\n" "$var_name" "$token"
            } >> "$config_file"
            echo -e "${GREEN}✓${NC} Token saved to $config_file"
        fi
        echo ""
        echo -e "${YELLOW}Important:${NC} Run ${CYAN}source $config_file${NC} or restart your terminal"
        echo ""

        # Set for current session
        export "$var_name"="$token"
    else
        echo -e "${YELLOW}Note:${NC} Token is set for this session only."
        echo -e "To use it permanently, add this to your $config_file:"
        echo -e "${CYAN}export $var_name=\"$token\"${NC}"
        echo ""
        export "$var_name"="$token"
    fi

    return 0
}

# Main interactive setup - configure multiple providers
setup_credentials_interactive() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                  ║${NC}"
    echo -e "${CYAN}║     ${BLUE}ClaudeSwap Credential Setup${NC}                 ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                  ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}This wizard will help you configure API credentials.${NC}"
    echo -e "${BLUE}All credentials are stored locally in your shell config.${NC}"
    echo ""

    local config_file
    config_file=$(detect_shell_config)
    log_info "Detected config file: ${CYAN}$config_file${NC}"
    echo ""

    echo "Configure which providers? (You can configure multiple)"
    echo ""
    echo "  1. Z.ai (GLM models: glm-4.6, glm-4.5)"
    echo "  2. MiniMax (MiniMax-M2, MiniMax-M1)"
    echo "  3. Kimi/Moonshot (kimi-k2-turbo, moonshot-v1-256k)"
    echo "  4. All providers (configure all at once)"
    echo "  5. Skip / I'll configure manually"
    echo ""

    # NASA Rule 2: Fixed bound on interactive loop
    local attempt=0
    while [[ $attempt -lt $MAX_INTERACTIVE_ATTEMPTS ]]; do
        attempt=$((attempt + 1))
        printf "Select option (1-5): "
        read -r choice

        case "$choice" in
            1)
                setup_service_credentials "Z.ai" "CLAUDE_ZAI_AUTH_TOKEN" "https://z.ai/manage-apikey/apikey-list"
                echo ""
                printf "Configure another provider? (y/n): "
                read -r continue
                [[ ! $continue =~ ^[Yy]$ ]] && break
                ;;
            2)
                setup_service_credentials "MiniMax" "CLAUDE_MINIMAX_AUTH_TOKEN" "https://platform.minimax.io/user-center/basic-information/interface-key"
                echo ""
                printf "Configure another provider? (y/n): "
                read -r continue
                [[ ! $continue =~ ^[Yy]$ ]] && break
                ;;
            3)
                setup_service_credentials "Kimi/Moonshot" "CLAUDE_KIMI_AUTH_TOKEN" "https://platform.moonshot.cn/console/api-keys"
                echo ""
                # Ask about Kimi for Coding
                echo -e "${BLUE}Do you have Kimi for Coding membership?${NC}"
                printf "(y/n): "
                read -r has_coding
                if [[ $has_coding =~ ^[Yy]$ ]]; then
                    # Add Kimi for Coding endpoint to config
                    if grep -qF "export CLAUDE_KIMI_FOR_CODING_BASE_URL=" "$config_file" 2>/dev/null; then
                        log_info "Kimi for Coding already configured"
                    else
                        {
                            echo ""
                            echo "# Kimi for Coding - Official Moonshot Coding Plan"
                            echo 'export CLAUDE_KIMI_FOR_CODING_BASE_URL="https://api.kimi.com/coding/"'
                        } >> "$config_file"
                        echo -e "${GREEN}✓${NC} Kimi for Coding endpoint configured!"
                    fi
                fi
                echo ""
                printf "Configure another provider? (y/n): "
                read -r continue
                [[ ! $continue =~ ^[Yy]$ ]] && break
                ;;
            4)
                # Configure all providers
                echo ""
                echo -e "${BLUE}Configuring all providers...${NC}"
                echo ""

                # Z.ai
                echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                printf "Do you have Z.ai access? (y/n): "
                read -r has_zai
                if [[ $has_zai =~ ^[Yy]$ ]]; then
                    setup_service_credentials "Z.ai" "CLAUDE_ZAI_AUTH_TOKEN" "https://z.ai/manage-apikey/apikey-list"
                fi

                # MiniMax
                echo ""
                echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                printf "Do you have MiniMax access? (y/n): "
                read -r has_minimax
                if [[ $has_minimax =~ ^[Yy]$ ]]; then
                    setup_service_credentials "MiniMax" "CLAUDE_MINIMAX_AUTH_TOKEN" "https://platform.minimax.io/user-center/basic-information/interface-key"
                fi

                # Kimi/Moonshot
                echo ""
                echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                printf "Do you have Kimi/Moonshot access? (y/n): "
                read -r has_kimi
                if [[ $has_kimi =~ ^[Yy]$ ]]; then
                    setup_service_credentials "Kimi/Moonshot" "CLAUDE_KIMI_AUTH_TOKEN" "https://platform.moonshot.cn/console/api-keys"

                    # Ask about Kimi for Coding
                    echo ""
                    printf "Do you have Kimi for Coding membership? (y/n): "
                    read -r has_coding
                    if [[ $has_coding =~ ^[Yy]$ ]]; then
                        if ! grep -qF "export CLAUDE_KIMI_FOR_CODING_BASE_URL=" "$config_file" 2>/dev/null; then
                            {
                                echo ""
                                echo "# Kimi for Coding - Official Moonshot Coding Plan"
                                echo 'export CLAUDE_KIMI_FOR_CODING_BASE_URL="https://api.kimi.com/coding/"'
                            } >> "$config_file"
                            echo -e "${GREEN}✓${NC} Kimi for Coding endpoint configured!"
                        fi
                    fi
                fi
                break
                ;;
            5)
                log_info "Skipping automated setup"
                echo ""
                echo "To configure manually, add these to your $config_file:"
                echo ""
                echo -e "${CYAN}# Z.ai${NC}"
                echo 'export CLAUDE_ZAI_AUTH_TOKEN="your-token"'
                echo 'export CLAUDE_ZAI_BASE_URL="https://api.z.ai/api/anthropic"'
                echo ""
                echo -e "${CYAN}# MiniMax${NC}"
                echo 'export CLAUDE_MINIMAX_AUTH_TOKEN="your-token"'
                echo 'export CLAUDE_MINIMAX_BASE_URL="https://api.minimax.io/anthropic"'
                echo ""
                echo -e "${CYAN}# Kimi/Moonshot${NC}"
                echo 'export CLAUDE_KIMI_AUTH_TOKEN="your-token"'
                echo 'export CLAUDE_KIMI_BASE_URL="https://api.moonshot.cn/v1"'
                echo ""
                return 0
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, 3, 4, or 5"
                ;;
        esac
    done

    # If we hit max attempts, log warning
    if [[ $attempt -ge $MAX_INTERACTIVE_ATTEMPTS ]]; then
        log_warning "Maximum attempts reached. Setup cancelled."
        return 1
    fi

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ Setup complete!${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log_info "To apply changes, run: ${CYAN}source $config_file${NC}"
    log_info "Or restart your terminal"
    echo ""
    echo "Next steps:"
    echo "  ${YELLOW}claudeswap status${NC}          - Check current configuration"
    echo "  ${YELLOW}claudeswap set <provider>${NC}  - Switch providers"
    echo "  ${YELLOW}claudeswap <provider> <cmd>${NC} - Execute with provider (CCS-style)"
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

    # NASA Rule 2: Fixed bound on interactive loop
    local attempt=0
    while [[ $attempt -lt $MAX_INTERACTIVE_ATTEMPTS ]]; do
        attempt=$((attempt + 1))
        echo "" >&2
        printf "Select model (1-${#available_models[@]}) or press Enter for default: " >&2
        read -r choice

        if [[ -z "$choice" ]]; then
            # Default selection
            case "$provider" in
                "standard") echo "claude-sonnet-4-5-20250929" ;;
                "minimax") echo "MiniMax-M2" ;;
                "zai"|"glm") echo "glm-4.6" ;;
                "kimi"|"moonshot") echo "moonshot-v1-256k" ;;
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

    # If we hit max attempts, log warning and return default
    if [[ $attempt -ge $MAX_INTERACTIVE_ATTEMPTS ]]; then
        log_warning "Maximum attempts reached. Using default model." >&2
        case "$provider" in
            "standard") echo "claude-sonnet-4-5-20250929" ;;
            "minimax") echo "MiniMax-M2" ;;
            "zai"|"glm") echo "glm-4.6" ;;
            "kimi"|"moonshot") echo "moonshot-v1-256k" ;;
        esac
        return 0
    fi
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
    # Export both AUTH_TOKEN and API_KEY for compatibility
    export ZAI_AUTH_TOKEN
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
    # Export both AUTH_TOKEN and API_KEY for compatibility
    export MINIMAX_AUTH_TOKEN
    export MINIMAX_API_KEY="$MINIMAX_AUTH_TOKEN"
    export MINIMAX_BASE_URL="${MINIMAX_BASE_URL:-$MINIMAX_BASE_URL_DEFAULT}"
    export MINIMAX_TIMEOUT="${MINIMAX_TIMEOUT:-$MINIMAX_TIMEOUT_DEFAULT}"

    log_success "MiniMax credentials configured"
}

# Setup Kimi/Moonshot credentials
setup_kimi_credentials() {
    if [[ -z "$KIMI_AUTH_TOKEN" ]]; then
        log_error "Kimi/Moonshot credentials not configured!"
        echo ""
        echo "To configure manually:"
        echo 'export CLAUDE_KIMI_AUTH_TOKEN="your-kimi-token-here"'
        echo 'export CLAUDE_KIMI_BASE_URL="https://api.moonshot.cn/v1"'
        echo ""
        echo "Or run: claudeswap setup"
        return 1
    fi

    # Set environment for Kimi/Moonshot
    # Export both AUTH_TOKEN and API_KEY for compatibility
    export KIMI_AUTH_TOKEN
    export KIMI_API_KEY="$KIMI_AUTH_TOKEN"
    export KIMI_BASE_URL="${KIMI_BASE_URL:-$KIMI_BASE_URL_DEFAULT}"
    export KIMI_TIMEOUT="${KIMI_TIMEOUT:-$KIMI_TIMEOUT_DEFAULT}"

    log_success "Kimi/Moonshot credentials configured"
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
            elif [[ "$service" == "Kimi" ]] || [[ "$service" == "Moonshot" ]]; then
                setup_service_credentials "Kimi/Moonshot" "CLAUDE_KIMI_AUTH_TOKEN" "https://platform.moonshot.cn/console/api-keys"
            fi
            # Refresh the token variable after interactive setup
            if [[ "$service" == "Z.ai" ]]; then
                token="${CLAUDE_ZAI_AUTH_TOKEN:-}"
            elif [[ "$service" == "MiniMax" ]]; then
                token="${CLAUDE_MINIMAX_AUTH_TOKEN:-}"
            elif [[ "$service" == "Kimi" ]] || [[ "$service" == "Moonshot" ]]; then
                token="${CLAUDE_KIMI_AUTH_TOKEN:-}"
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
            elif [[ "$service" == "Kimi" ]] || [[ "$service" == "Moonshot" ]]; then
                echo "export CLAUDE_KIMI_AUTH_TOKEN=\"your-kimi-token-here\""
                echo "export CLAUDE_KIMI_BASE_URL=\"https://api.moonshot.cn/v1\""
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
