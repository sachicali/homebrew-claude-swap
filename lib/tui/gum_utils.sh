#!/usr/bin/env bash

# Gum utilities and dependency management
# Single Responsibility: Gum integration and helper functions

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# Check if Gum is installed
check_gum_installed() {
    if command -v gum >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Get Gum version
get_gum_version() {
    if ! check_gum_installed; then
        echo "not_installed"
        return 1
    fi

    gum --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"
}

# Show Gum installation instructions
show_gum_install_instructions() {
    cat <<'EOF'

╭─────────────────────────────────────────────────────────────────╮
│                  Gum Not Installed                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ClaudeSwap's TUI mode requires Gum (Charmbracelet).            │
│  Please install it using one of these methods:                  │
│                                                                  │
│  macOS:                                                          │
│    brew install gum                                              │
│                                                                  │
│  Linux (Debian/Ubuntu):                                          │
│    sudo mkdir -p /etc/apt/keyrings                               │
│    curl -fsSL https://repo.charm.sh/apt/gpg.key | \              │
│      sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg          │
│    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] \           │
│      https://repo.charm.sh/apt/ * *" | \                         │
│      sudo tee /etc/apt/sources.list.d/charm.list                 │
│    sudo apt update && sudo apt install gum                       │
│                                                                  │
│  Linux (Fedora/RHEL):                                            │
│    echo '[charm]                                                 │
│    name=Charm                                                    │
│    baseurl=https://repo.charm.sh/yum/                            │
│    enabled=1                                                     │
│    gpgcheck=1                                                    │
│    gpgkey=https://repo.charm.sh/yum/gpg.key' | \                 │
│      sudo tee /etc/yum.repos.d/charm.repo                        │
│    sudo yum install gum                                          │
│                                                                  │
│  Arch Linux:                                                     │
│    pacman -S gum                                                 │
│                                                                  │
│  Any Platform (using Go):                                        │
│    go install github.com/charmbracelet/gum@latest               │
│                                                                  │
│  Fallback to CLI mode:                                           │
│    claudeswap --no-tui <command>                                 │
│                                                                  │
╰─────────────────────────────────────────────────────────────────╯

EOF
}

# Ensure Gum is available or fallback gracefully
ensure_gum() {
    if ! check_gum_installed; then
        show_gum_install_instructions
        echo "TIP: You can still use claudeswap in CLI mode without Gum." >&2
        return 1
    fi
    return 0
}
