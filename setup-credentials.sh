#!/usr/bin/env bash
#
# ClaudeSwap Credential Setup Script
# Automatically configures API credentials in your shell configuration
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emoji support
CHECKMARK="✓"
CROSS="✗"
ARROW="→"
INFO="ℹ"

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}ClaudeSwap Credential Setup${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}${INFO}${NC} $1"
}

print_success() {
    echo -e "${GREEN}${CHECKMARK}${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}${ARROW}${NC} $1"
}

print_error() {
    echo -e "${RED}${CROSS}${NC} $1"
}

# Detect shell and config file
detect_shell() {
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

# Check if configuration already exists
check_existing_config() {
    local config_file="$1"
    local provider="$2"

    if [[ -f "$config_file" ]]; then
        grep -q "CLAUDE_${provider}_AUTH_TOKEN" "$config_file" 2>/dev/null
    else
        return 1
    fi
}

# Read password/token securely (with masking)
read_token() {
    local prompt="$1"
    local token=""

    # Try to use read -s for password masking
    if read -s -p "$prompt" token 2>/dev/null; then
        echo "$token"
    else
        # Fallback for systems that don't support -s
        read -p "$prompt" token
        echo "$token"
    fi
}

# Add or update environment variable in config file
add_to_config() {
    local config_file="$1"
    local var_name="$2"
    local var_value="$3"
    local section_comment="$4"

    # Create config file if it doesn't exist
    touch "$config_file"

    # Check if variable already exists
    if grep -q "^export ${var_name}=" "$config_file" 2>/dev/null; then
        # Update existing variable (using sed compatible with both GNU and BSD)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS (BSD sed)
            sed -i '' "s|^export ${var_name}=.*|export ${var_name}=\"${var_value}\"|" "$config_file"
        else
            # Linux (GNU sed)
            sed -i "s|^export ${var_name}=.*|export ${var_name}=\"${var_value}\"|" "$config_file"
        fi
        print_success "Updated $var_name"
    else
        # Add new variable
        {
            echo ""
            echo "# $section_comment"
            echo "export ${var_name}=\"${var_value}\""
        } >> "$config_file"
        print_success "Added $var_name"
    fi
}

# Setup Z.ai credentials
setup_zai() {
    local config_file="$1"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Z.ai Configuration${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if check_existing_config "$config_file" "ZAI"; then
        print_warning "Z.ai credentials already configured"
        read -p "Update? (y/N): " update
        if [[ ! "$update" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    print_info "Get your token from: ${YELLOW}https://z.ai/manage-apikey/apikey-list${NC}"
    echo ""

    read -p "Do you have a Z.ai API token? (y/N): " has_token
    if [[ "$has_token" =~ ^[Yy]$ ]]; then
        echo -n "Enter Z.ai token (hidden): "
        local token
        token=$(read_token "")
        echo "" # New line after hidden input

        if [[ -n "$token" ]]; then
            add_to_config "$config_file" "CLAUDE_ZAI_AUTH_TOKEN" "$token" "Z.ai Configuration"
            add_to_config "$config_file" "CLAUDE_ZAI_BASE_URL" "https://api.z.ai/api/anthropic" "Z.ai Configuration"
            print_success "Z.ai credentials configured!"
        else
            print_error "Token cannot be empty. Skipping Z.ai setup."
        fi
    else
        print_info "Skipping Z.ai setup (optional)"
    fi
}

# Setup MiniMax credentials
setup_minimax() {
    local config_file="$1"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}MiniMax Configuration${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if check_existing_config "$config_file" "MINIMAX"; then
        print_warning "MiniMax credentials already configured"
        read -p "Update? (y/N): " update
        if [[ ! "$update" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    print_info "Get your token from: ${YELLOW}https://platform.minimax.io/user-center/basic-information/interface-key${NC}"
    echo ""

    read -p "Do you have a MiniMax API token? (y/N): " has_token
    if [[ "$has_token" =~ ^[Yy]$ ]]; then
        echo -n "Enter MiniMax token (hidden): "
        local token
        token=$(read_token "")
        echo "" # New line after hidden input

        if [[ -n "$token" ]]; then
            add_to_config "$config_file" "CLAUDE_MINIMAX_AUTH_TOKEN" "$token" "MiniMax Configuration"
            add_to_config "$config_file" "CLAUDE_MINIMAX_BASE_URL" "https://api.minimax.io/anthropic" "MiniMax Configuration"
            print_success "MiniMax credentials configured!"
        else
            print_error "Token cannot be empty. Skipping MiniMax setup."
        fi
    else
        print_info "Skipping MiniMax setup (optional)"
    fi
}

# Setup Kimi/Moonshot credentials
setup_kimi() {
    local config_file="$1"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Kimi/Moonshot Configuration${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if check_existing_config "$config_file" "KIMI"; then
        print_warning "Kimi credentials already configured"
        read -p "Update? (y/N): " update
        if [[ ! "$update" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    print_info "Get your token from: ${YELLOW}https://platform.moonshot.cn/console/api-keys${NC}"
    echo ""

    read -p "Do you have a Kimi/Moonshot API token? (y/N): " has_token
    if [[ "$has_token" =~ ^[Yy]$ ]]; then
        echo -n "Enter Kimi/Moonshot token (hidden): "
        local token
        token=$(read_token "")
        echo "" # New line after hidden input

        if [[ -n "$token" ]]; then
            add_to_config "$config_file" "CLAUDE_KIMI_AUTH_TOKEN" "$token" "Kimi/Moonshot Configuration"
            add_to_config "$config_file" "CLAUDE_KIMI_BASE_URL" "https://api.moonshot.cn/v1" "Kimi/Moonshot Configuration"

            # Ask about Kimi for Coding
            echo ""
            read -p "Do you have Kimi for Coding membership? (y/N): " has_coding
            if [[ "$has_coding" =~ ^[Yy]$ ]]; then
                add_to_config "$config_file" "CLAUDE_KIMI_FOR_CODING_BASE_URL" "https://api.kimi.com/coding/" "Kimi for Coding Configuration"
                print_success "Kimi for Coding endpoint configured!"
            fi

            print_success "Kimi credentials configured!"
        else
            print_error "Token cannot be empty. Skipping Kimi setup."
        fi
    else
        print_info "Skipping Kimi setup (optional)"
    fi
}

# Setup standard timeout
setup_standard() {
    local config_file="$1"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Standard Anthropic Configuration${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    print_info "Setting standard timeout to 120000ms (2 minutes)"
    add_to_config "$config_file" "CLAUDE_STANDARD_TIMEOUT" "120000" "Standard Anthropic Configuration"
}

# Main setup function
main() {
    print_header

    print_info "This script will help you configure ClaudeSwap credentials"
    print_warning "All credentials are stored locally in your shell configuration"
    echo ""

    # Detect shell config file
    local config_file
    config_file=$(detect_shell)

    print_info "Detected config file: ${YELLOW}$config_file${NC}"

    # Backup config file
    if [[ -f "$config_file" ]]; then
        local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$config_file" "$backup_file"
        print_success "Created backup: $backup_file"
    fi

    # Setup each provider
    setup_zai "$config_file"
    setup_minimax "$config_file"
    setup_kimi "$config_file"
    setup_standard "$config_file"

    # Final instructions
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}${CHECKMARK} Setup Complete!${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    print_info "To apply changes, run:"
    echo -e "  ${YELLOW}source $config_file${NC}"
    echo ""
    print_info "Or restart your terminal"
    echo ""
    print_info "Then test with:"
    echo -e "  ${YELLOW}claudeswap status${NC}"
    echo ""
}

# Run main function
main "$@"
