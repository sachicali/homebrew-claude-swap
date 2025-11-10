# Claude Swap

**Version 1.5.0** | [Release Notes](RELEASE_NOTES_v1.5.0.md) | [Changelog](CHANGELOG.md)

A safe and robust tool to swap between multiple AI providers: GLM (Z.ai), MiniMax, Kimi/Moonshot, and standard Anthropic Claude with dynamic model mapping, concurrent execution, and performance optimization.

## ✨ What's New in v1.5.0

**🚀 Major Features:**
- **CCS-Style Concurrent Execution** - Run multiple providers simultaneously with instance isolation
- **Official Kimi for Coding** - Full support for Moonshot's coding membership plan
- **Kimi K2 Turbo** - 4x faster performance at 40 tokens/sec
- **Auto-Installer** - One-line installation with bundled Gum

**🐛 Critical Fixes:**
- Fixed syntax error in model mapping (duplicate semicolon)
- Updated version consistency across all components
- Bash 3.2 compatibility improvements
- Centralized configuration constants

**📚 Full Details:** See [Release Notes](RELEASE_NOTES_v1.5.0.md) for complete changelog and upgrade instructions.

## ⚠️ IMPORTANT: Set Your Credentials First

Before using this tool, you MUST configure your own API credentials:

### 1. Add to Your Shell Configuration

Edit `~/.zshrc` (or `~/.bashrc`):

```bash
# Z.ai Configuration (optional - only if you have access)
export CLAUDE_ZAI_AUTH_TOKEN="your-zai-token-here"
export CLAUDE_ZAI_BASE_URL="https://api.z.ai/api/anthropic"

# MiniMax Configuration (optional - only if you have access)
export CLAUDE_MINIMAX_AUTH_TOKEN="your-minimax-token-here"
export CLAUDE_MINIMAX_BASE_URL="https://api.minimax.io/anthropic"

# Kimi/Moonshot Configuration (optional - only if you have access)
export CLAUDE_KIMI_AUTH_TOKEN="your-kimi-token-here"
export CLAUDE_KIMI_BASE_URL="https://api.moonshot.cn/v1"  # For regular kimi profile

# Kimi for Coding - Official Moonshot Coding Plan (optional)
# Uses same auth token but dedicated coding endpoint
# export CLAUDE_KIMI_FOR_CODING_BASE_URL="https://api.kimi.com/coding/"  # Already default

# Standard timeout (default is 2 minutes)
export CLAUDE_STANDARD_TIMEOUT="120000"
```

**Replace `your-zai-token-here`, `your-minimax-token-here`, and `your-kimi-token-here` with your actual tokens!**

### 2. Reload Your Shell

```bash
source ~/.zshrc
```

## Installation

### Option 1: Auto-Installer (Recommended - NEW!)

**One-line install with bundled Gum:**

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/sachicali/homebrew-claudeswap/main/install.sh | bash

# Or download and run:
wget https://raw.githubusercontent.com/sachicali/homebrew-claudeswap/main/install.sh
chmod +x install.sh
./install.sh
```

**Benefits:**
- Automatically downloads and installs claudeswap
- Bundles Gum binary for your platform (no separate install needed!)
- Configures PATH in your shell
- Creates instance directories
- Works on macOS, Linux (x86_64, arm64, armv7)

### Option 2: Homebrew

```bash
# Install from the GitHub repository
brew install sachicali/homebrew-claudeswap/claudeswap

# Then install Gum for TUI mode:
brew install gum
```

### Option 3: Manual Homebrew Formula

1. Tap the repository:
```bash
brew tap sachicali/claudeswap
```

2. Install the formula:
```bash
brew install claudeswap
```

## 🎨 TUI Mode (NEW in v1.3.0!)

ClaudeSwap now features an interactive TUI (Text User Interface) powered by [Charmbracelet Gum](https://github.com/charmbracelet/gum)!

### Installing Gum (Required for TUI)

```bash
# macOS
brew install gum

# Linux (Debian/Ubuntu)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum

# Arch Linux
pacman -S gum
```

### Using TUI Mode

```bash
# Launch TUI mode (new default behavior)
claudeswap

# Or explicitly:
claudeswap tui
claudeswap --tui
```

**TUI Features:**
- 🔄 **Interactive Provider Selection** - Browse and switch providers with visual status indicators
- 🔧 **Guided Credential Setup** - Password-masked token input with validation
- 📊 **Provider Comparison Table** - Side-by-side comparison of all providers
- 🧪 **Searchable Model Filter** - Type-to-filter through hundreds of models
- 📈 **Beautiful Status Display** - Styled boxes and colors for better readability
- ⏳ **Loading Spinners** - Visual feedback for API calls
- ✓ **Confirmation Prompts** - Prevent accidental changes

**Without TUI (CLI Mode):**
```bash
# Force CLI mode if needed
claudeswap --no-tui status
```

## 🚀 CCS-Style Concurrent Execution (NEW in v1.5.0!)

Inspired by [CCS (Claude Code Switch)](https://github.com/kaitranntt/ccs), claudeswap now supports:

### Instance Isolation
Each provider gets its own isolated instance directory at `~/.claude/instances/<provider>/`:
- Separate session files
- Independent configuration
- No conflicts between providers

### Direct Command Execution
Execute Claude commands directly with provider switching:

```bash
# CCS-style shorthand - switch and execute in one command
claudeswap kimi "write a bash script"
claudeswap kimi-for-coding "implement authentication system"
claudeswap zai "fix this bug"
claudeswap standard "review code"

# Explicit exec command
claudeswap exec kimi "implement feature"
claudeswap exec kimi-for-coding "refactor this module"
```

### Concurrent Multi-Provider Usage
Run different providers simultaneously in separate terminals:

```bash
# Terminal 1: Coding tasks with optimized Kimi
claudeswap kimi-for-coding "implement authentication"

# Terminal 2: General queries with regular Kimi (no conflict!)
claudeswap kimi "explain this architecture"

# Terminal 3: Use Z.ai for testing
claudeswap zai "write comprehensive tests"

# Terminal 4: Standard API for quick queries
claudeswap standard "review this code snippet"
```

**Note:** `kimi-for-coding` uses the same Kimi credentials as regular `kimi`, but maintains a separate instance directory for coding-focused sessions. This allows you to run both concurrently!

### Instance Management

```bash
# List all provider instances
claudeswap instances
claudeswap list

# Initialize new instance
claudeswap init kimi

# Activate specific instance
claudeswap activate zai
```

### Custom Claude Path
Set custom Claude CLI location:

```bash
export CLAUDESWAP_CLAUDE_PATH="/custom/path/to/claude"
claudeswap kimi "write code"
```

## Usage

### CLI Mode Commands

```bash
# Switch to Z.ai (50min timeout)
claudeswap set zai

# Switch to MiniMax (50min timeout, MiniMax-M2 model)
claudeswap set minimax

# Switch to Kimi/Moonshot (50min timeout, 256K context)
claudeswap set kimi

# Switch to standard Anthropic (2min timeout)
claudeswap set standard

# Check current status
claudeswap status

# Interactive credential setup
claudeswap setup

# Test dynamic model mapping system
claudeswap test-models

# Session management
claudeswap clear     # Clear all sessions
claudeswap backup    # Backup current sessions

# Show help
claudeswap help

# Show version
claudeswap version
```

## What Gets Changed

### Z.ai Configuration (GLM Provider)
- Base URL: `https://api.z.ai/api/anthropic`
- Timeout: 3000000ms (50 minutes)
- Uses your `CLAUDE_ZAI_AUTH_TOKEN`
- Provides access to GLM models through Z.ai API

### MiniMax Configuration
- Base URL: `https://api.minimax.io/anthropic`
- Timeout: 3000000ms (50 minutes)
- Model: MiniMax-M2
- All model variants set to MiniMax-M2
- Uses your `CLAUDE_MINIMAX_AUTH_TOKEN`

### Kimi/Moonshot Configuration

**Regular Kimi (`kimi`):**
- Base URL: `https://api.moonshot.cn/v1`
- Model: **kimi-k2-turbo-preview** ⚡ (4x faster than standard K2!)
- Speed: 40 tokens/sec (vs 10 tok/s for regular K2)
- Released: August 2025
- Timeout: 3000000ms (50 minutes)
- Temperature: 0.6x multiplier
- Uses your `CLAUDE_KIMI_AUTH_TOKEN`
- Context: Up to 256K tokens
- Cost: $0.30/$1.20/$5.00 per million tokens (cache hit/miss/output)
- Best for: General queries, fast responses, explanations, documentation

**Kimi for Coding (`kimi-for-coding`) - 🎯 OFFICIAL Moonshot Coding Plan:**
- Base URL: `https://api.kimi.com/coding/` (Dedicated coding endpoint!)
- Model: **kimi-for-coding** (Official membership-based coding plan)
- **This is an OFFICIAL Moonshot product** - not just a model variant
- Requires: Moonshot membership subscription
- Optimized for: Professional coding tasks, complex algorithms, refactoring
- Features: Code-specific training, enhanced tool calling, agentic workflows
- Best for: Production code, complex implementations, enterprise development
- Uses your `CLAUDE_KIMI_AUTH_TOKEN` (same token, different endpoint)
- Compatible with: Claude Code, Cline, RooCode (via ANTHROPIC_BASE_URL)

### Standard Configuration
- Base URL: (removed/blank)
- Timeout: 120000ms (2 minutes) - customizable via `CLAUDE_STANDARD_TIMEOUT`
- Restores your original API key

## 🎯 Key Features

### Dynamic Model Mapping
- **Universal Model Support**: Automatically detects and maps any model type (sonnet, haiku, opus, GLM, MiniMax, Kimi)
- **Provider-Agnostic**: Seamlessly switch between Anthropic, MiniMax, GLM, and Kimi/Moonshot providers
- **Smart Detection**: Identifies model families and performance tiers
- **Future-Proof**: Handles new model releases automatically

### Concurrent Multi-Provider Support (v1.5.0)
- **Instance Isolation**: Each provider gets its own `~/.claude/instances/<provider>/` directory
- **Zero Conflicts**: Run different providers simultaneously in separate terminals
- **Direct Execution**: `claudeswap kimi "write code"` shorthand syntax
- **CCS-Compatible**: Inspired by Claude Code Switch architecture

### Session Compatibility
- **Fixes `claude --continue` Errors**: Resolves "Unknown Model" and "Invalid signature" issues
- **Session Transformation**: Automatically normalizes sessions for provider compatibility
- **Interactive Options**: Choose to transform, backup, or clear sessions when switching
- **Preserved History**: Maintain conversation continuity across providers

### Performance & Reliability
- **Bash 3.2 Compatible**: Works on macOS default bash and all modern systems
- **NASA-Style Safety**: Error checking, bounded loops, atomic operations
- **Smart Caching**: Model extraction cache with LRU eviction
- **Optimized Processing**: Fast JSON operations and provider switching

## Safety Features

- ✅ Automatic backups before every change
- ✅ JSON validation before writing
- ✅ Auto-rollback on errors
- ✅ Backup rotation (keeps 10 most recent)
- ✅ Preserves your original auth token
- ✅ **No hardcoded credentials** - you provide your own tokens
- ✅ **Session compatibility checks** with transformation options
- ✅ **Performance optimizations** with fallback support

## Requirements

### Core Requirements
- macOS or Linux
- `jq` (installable via Homebrew: `brew install jq`)
- Zsh shell (default on macOS) or Bash

### Optional (Enhances Experience)
- `gum` (for TUI mode: `brew install gum`) - **Highly Recommended**
- `GNU parallel` (for performance optimization: `brew install parallel`)

## Performance Benchmarks

Based on testing with typical workloads:

- **Model Mapping**: ~3.3 seconds for 3000 operations (~1100 ops/sec)
- **Session Transformation**: 2-8x faster with parallel processing
- **File Discovery**: Optimized directory scanning
- **Memory Usage**: Efficient caching with 100-entry limit

Run `claudeswap benchmark` to test performance on your system.

## Where to Get API Tokens

### Z.ai
Visit: https://z.ai/manage-apikey/apikey-list

### MiniMax
Visit: https://platform.minimax.io/user-center/basic-information/interface-key

### Kimi/Moonshot
Visit: https://platform.moonshot.cn/console/api-keys

### Standard Anthropic
Your standard Anthropic API key: https://console.anthropic.com/

## Configuration File Location

```
~/.claude/settings.json
```

Backups are automatically created in:
```
~/.claude/backups/settings_YYYYMMDD_HHMMSS.json
```

## Environment Variables

### Provider Configuration

You can customize all timeouts and URLs:

```bash
# Z.ai (optional)
export CLAUDE_ZAI_AUTH_TOKEN="your-token"
export CLAUDE_ZAI_BASE_URL="custom-url-if-needed"
export CLAUDE_ZAI_TIMEOUT="3000000"  # 50 minutes

# MiniMax (optional)
export CLAUDE_MINIMAX_AUTH_TOKEN="your-token"
export CLAUDE_MINIMAX_BASE_URL="custom-url-if-needed"
export CLAUDE_MINIMAX_TIMEOUT="3000000"  # 50 minutes

# Kimi/Moonshot (optional)
export CLAUDE_KIMI_AUTH_TOKEN="your-token"
export CLAUDE_KIMI_BASE_URL="https://api.moonshot.cn/v1"
export CLAUDE_KIMI_TIMEOUT="3000000"  # 50 minutes

# Kimi for Coding (optional - uses same auth token)
export CLAUDE_KIMI_FOR_CODING_BASE_URL="https://api.kimi.com/coding/"
export CLAUDE_KIMI_FOR_CODING_TIMEOUT="3000000"  # 50 minutes

# Standard
export CLAUDE_STANDARD_TIMEOUT="120000"  # 2 minutes
```

### ClaudeSwap Configuration (v1.5.0+)

```bash
# Custom Claude CLI path (like CCS)
export CLAUDESWAP_CLAUDE_PATH="/custom/path/to/claude"

# Custom installation directories
export CLAUDESWAP_INSTALL_DIR="$HOME/.local/bin"
export CLAUDESWAP_LIB_DIR="$HOME/.local/lib/claudeswap"

# TUI mode preference
export CLAUDESWAP_TUI_MODE="auto"  # auto, always, never
```

## Upgrading

### From v1.2.x to v1.5.0

```bash
# If installed via Homebrew
brew update
brew upgrade claudeswap

# If installed via install.sh
curl -fsSL https://raw.githubusercontent.com/sachicali/homebrew-claudeswap/main/install.sh | bash

# Reload your shell
source ~/.zshrc
```

**Note:** v1.5.0 is fully backward compatible - no breaking changes!

## Uninstallation

```bash
# Homebrew installation
brew uninstall claudeswap
brew untap sachicali/claudeswap

# Manual installation
rm -f ~/.local/bin/claudeswap
rm -rf ~/.local/lib/claudeswap
# Remove PATH entry from ~/.zshrc or ~/.bashrc
```

## Troubleshooting

### "Z.ai credentials not configured"
Make sure you set `CLAUDE_ZAI_AUTH_TOKEN` in your `~/.zshrc`

### "MiniMax credentials not configured"
Make sure you set `CLAUDE_MINIMAX_AUTH_TOKEN` in your `~/.zshrc`

### "Kimi/Moonshot credentials not configured"
Make sure you set `CLAUDE_KIMI_AUTH_TOKEN` in your `~/.zshrc`

### jq not found
```bash
brew install jq
```

### Token not working
1. Verify your token is correct
2. Check the token hasn't expired
3. Ensure you reloaded your shell: `source ~/.zshrc`

## Security

- **Your tokens stay on your machine** - never stored in the repository
- Tokens stored only in your environment variables
- Automatic backups of settings (without exposing tokens)
- All token validation is local
- Atomic file operations prevent corruption
- Input sanitization prevents injection attacks

For security concerns or to report vulnerabilities, see [SECURITY.md](SECURITY.md)

## Documentation

- **[Release Notes](RELEASE_NOTES_v1.5.0.md)** - What's new in v1.5.0
- **[Changelog](CHANGELOG.md)** - Complete version history
- **[Security](SECURITY.md)** - Security best practices and reporting
- **[Architecture](ARCHITECTURE.md)** - System design and components
- **[Setup Guide](SETUP-GUIDE.md)** - Detailed setup instructions
- **[Example Configs](example-configs.md)** - Configuration examples

## Acknowledgments

**Inspired by:**
- **[CCS (Claude Code Switch)](https://github.com/kaitranntt/ccs)** - Instance isolation and concurrent execution architecture
- **[Charmbracelet Gum](https://github.com/charmbracelet/gum)** - Beautiful TUI components
- **Moonshot AI** - Official Kimi for Coding integration

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - See [LICENSE](LICENSE) for details

---

**ClaudeSwap v1.5.0** - Swap AI providers with confidence 🚀
