# Claude Swap

A safe and robust tool to swap between Z.ai, MiniMax, and standard Anthropic Claude configurations.

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

# Standard timeout (default is 2 minutes)
export CLAUDE_STANDARD_TIMEOUT="120000"
```

**Replace `your-zai-token-here` and `your-minimax-token-here` with your actual tokens!**

### 2. Reload Your Shell

```bash
source ~/.zshrc
```

## Installation

### Option 1: From GitHub (Recommended)

```bash
# Install from the GitHub repository
brew install sachicali/homebrew-cloud-swap/claude-swap
```

### Option 2: Manual Homebrew Formula

1. Tap the repository:
```bash
brew tap sachicali/homebrew-cloud-swap
```

2. Install the formula:
```bash
brew install claude-swap
```

## Usage

```bash
# Switch to Z.ai (50min timeout)
claude-swap zai

# Switch to MiniMax (50min timeout, MiniMax-M2 model)
claude-swap minimax

# Switch to standard Anthropic (2min timeout)
claude-swap standard

# Check current status
claude-swap status

# Restore from latest backup
claude-swap restore

# Show help
claude-swap help
```

## What Gets Changed

### Z.ai Configuration
- Base URL: `https://api.z.ai/api/anthropic`
- Timeout: 3000000ms (50 minutes)
- Uses your `CLAUDE_ZAI_AUTH_TOKEN`

### MiniMax Configuration
- Base URL: `https://api.minimax.io/anthropic`
- Timeout: 3000000ms (50 minutes)
- Model: MiniMax-M2
- All model variants set to MiniMax-M2
- Uses your `CLAUDE_MINIMAX_AUTH_TOKEN`

### Standard Configuration
- Base URL: (removed/blank)
- Timeout: 120000ms (2 minutes) - customizable via `CLAUDE_STANDARD_TIMEOUT`
- Restores your original API key

## Safety Features

- ✅ Automatic backups before every change
- ✅ JSON validation before writing
- ✅ Auto-rollback on errors
- ✅ Backup rotation (keeps 10 most recent)
- ✅ Preserves your original auth token
- ✅ **No hardcoded credentials** - you provide your own tokens

## Requirements

- macOS or Linux
- `jq` (installable via Homebrew: `brew install jq`)
- Zsh shell (default on macOS) or Bash

## Where to Get API Tokens

### Z.ai
Visit: https://z.ai/manage-apikey/apikey-list

### MiniMax
Visit: https://platform.minimax.io/user-center/basic-information/interface-key

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

# Standard
export CLAUDE_STANDARD_TIMEOUT="120000"  # 2 minutes
```

## Uninstallation

```bash
brew uninstall claude-swap
brew untap sachicali/homebrew-cloud-swap
```

## Troubleshooting

### "Z.ai credentials not configured"
Make sure you set `CLAUDE_ZAI_AUTH_TOKEN` in your `~/.zshrc`

### "MiniMax credentials not configured"
Make sure you set `CLAUDE_MINIMAX_AUTH_TOKEN` in your `~/.zshrc`

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

## License

MIT
