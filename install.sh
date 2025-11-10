#!/usr/bin/env bash

# ClaudeSwap Installer
# Auto-installs claudeswap with all dependencies including Gum

set -euo pipefail

readonly INSTALL_DIR="${CLAUDESWAP_INSTALL_DIR:-$HOME/.local/bin}"
readonly LIB_DIR="${CLAUDESWAP_LIB_DIR:-$HOME/.local/lib/claudeswap}"
readonly GUM_VERSION="v0.14.5"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Detect OS and architecture
detect_platform() {
    local os=""
    local arch=""

    # Detect OS
    case "$(uname -s)" in
        Linux*)     os="Linux" ;;
        Darwin*)    os="Darwin" ;;
        MINGW*|MSYS*|CYGWIN*) os="Windows" ;;
        *)
            log_error "Unsupported OS: $(uname -s)"
            exit 1
            ;;
    esac

    # Detect architecture
    case "$(uname -m)" in
        x86_64|amd64)   arch="x86_64" ;;
        aarch64|arm64)  arch="arm64" ;;
        armv7l)         arch="armv7" ;;
        *)
            log_error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac

    echo "${os}_${arch}"
}

# Download Gum binary for the platform
install_gum() {
    local platform="$1"
    local gum_binary="$INSTALL_DIR/gum"

    # Check if gum already installed
    if [[ -f "$gum_binary" ]]; then
        log_info "Gum already installed at $gum_binary"
        return 0
    fi

    log_info "Installing Gum ${GUM_VERSION} for ${platform}..."

    # Map our platform names to Gum release names
    local gum_platform=""
    case "$platform" in
        Darwin_x86_64)  gum_platform="Darwin_x86_64" ;;
        Darwin_arm64)   gum_platform="Darwin_arm64" ;;
        Linux_x86_64)   gum_platform="Linux_x86_64" ;;
        Linux_arm64)    gum_platform="Linux_arm64" ;;
        Linux_armv7)    gum_platform="Linux_armv7" ;;
        *)
            log_error "No Gum binary available for platform: $platform"
            return 1
            ;;
    esac

    local download_url="https://github.com/charmbracelet/gum/releases/download/${GUM_VERSION}/gum_${GUM_VERSION#v}_${gum_platform}.tar.gz"
    local temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" RETURN

    log_info "Downloading from: $download_url"

    if ! curl -fsSL "$download_url" -o "$temp_dir/gum.tar.gz"; then
        log_error "Failed to download Gum"
        return 1
    fi

    # Extract
    if ! tar -xzf "$temp_dir/gum.tar.gz" -C "$temp_dir"; then
        log_error "Failed to extract Gum"
        return 1
    fi

    # Move binary
    if [[ -f "$temp_dir/gum" ]]; then
        mkdir -p "$INSTALL_DIR"
        mv "$temp_dir/gum" "$gum_binary"
        chmod +x "$gum_binary"
        log_success "Gum installed to $gum_binary"
    else
        log_error "Gum binary not found in archive"
        return 1
    fi
}

# Install claudeswap
install_claudeswap() {
    log_info "Installing ClaudeSwap..."

    # Create directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$LIB_DIR"
    mkdir -p "$HOME/.claude"
    mkdir -p "$HOME/.claude/instances"

    # Check if running from git repo or curl install
    if [[ -f "$(dirname "$0")/claudeswap" ]]; then
        # Git clone / local install
        local source_dir="$(cd "$(dirname "$0")" && pwd)"
        log_info "Installing from local directory: $source_dir"

        # Copy main script
        cp "$source_dir/claudeswap" "$INSTALL_DIR/claudeswap"
        chmod +x "$INSTALL_DIR/claudeswap"

        # Copy library files
        if [[ -d "$source_dir/lib" ]]; then
            cp -r "$source_dir/lib" "$LIB_DIR/"
        fi

        log_success "ClaudeSwap installed from local source"
    else
        # Download from GitHub
        log_info "Downloading ClaudeSwap from GitHub..."
        local repo_url="https://github.com/sachicali/homebrew-claudeswap"
        local temp_dir=$(mktemp -d)
        trap "rm -rf '$temp_dir'" RETURN

        if ! git clone --depth 1 "$repo_url" "$temp_dir/claudeswap" 2>/dev/null; then
            log_error "Failed to clone repository"
            return 1
        fi

        # Copy files
        cp "$temp_dir/claudeswap/claudeswap" "$INSTALL_DIR/claudeswap"
        chmod +x "$INSTALL_DIR/claudeswap"

        if [[ -d "$temp_dir/claudeswap/lib" ]]; then
            cp -r "$temp_dir/claudeswap/lib" "$LIB_DIR/"
        fi

        log_success "ClaudeSwap downloaded and installed"
    fi

    # Update CLAUDE_SWAP_BASE_DIR in the installed script
    if [[ -f "$INSTALL_DIR/claudeswap" ]]; then
        # The script will auto-detect lib directory at runtime
        log_success "ClaudeSwap executable installed to $INSTALL_DIR/claudeswap"
    fi
}

# Add to PATH
setup_path() {
    log_info "Setting up PATH..."

    local shell_rc=""
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ -n "${BASH_VERSION:-}" ]] || [[ "$SHELL" == */bash ]]; then
        shell_rc="$HOME/.bashrc"
    else
        log_warning "Unknown shell, please add $INSTALL_DIR to PATH manually"
        return 0
    fi

    # Check if already in PATH
    if grep -q "$INSTALL_DIR" "$shell_rc" 2>/dev/null; then
        log_info "PATH already configured in $shell_rc"
        return 0
    fi

    # Add to PATH
    cat >> "$shell_rc" <<EOF

# ClaudeSwap - Added by installer
export PATH="\$PATH:$INSTALL_DIR"
export CLAUDESWAP_LIB_DIR="$LIB_DIR"
EOF

    log_success "Added $INSTALL_DIR to PATH in $shell_rc"
    log_warning "Please run: source $shell_rc"
}

# Main installation
main() {
    echo "╭─────────────────────────────────────────╮"
    echo "│     ClaudeSwap Installer v1.4.0         │"
    echo "╰─────────────────────────────────────────╯"
    echo ""

    log_info "Installing to: $INSTALL_DIR"
    log_info "Library directory: $LIB_DIR"
    echo ""

    # Detect platform
    local platform
    platform=$(detect_platform)
    log_info "Detected platform: $platform"

    # Install Gum
    if ! install_gum "$platform"; then
        log_warning "Gum installation failed - TUI mode will not be available"
        log_info "You can still use CLI mode"
    fi

    # Install ClaudeSwap
    if ! install_claudeswap; then
        log_error "ClaudeSwap installation failed"
        exit 1
    fi

    # Setup PATH
    setup_path

    echo ""
    echo "╭─────────────────────────────────────────╮"
    echo "│        Installation Complete! 🎉         │"
    echo "╰─────────────────────────────────────────╯"
    echo ""
    log_success "ClaudeSwap installed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Reload your shell: source ~/.zshrc (or ~/.bashrc)"
    echo "  2. Run: claudeswap"
    echo "  3. Set up your provider credentials"
    echo ""
}

main "$@"
