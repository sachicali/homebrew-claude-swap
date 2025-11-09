# Claude Swap

A safe and robust tool to swap between multiple AI providers: GLM (Z.ai), MiniMax, Kimi/Moonshot, and standard Anthropic Claude with dynamic model mapping and performance optimization.

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
export CLAUDE_KIMI_BASE_URL="https://api.moonshot.cn/v1"

# Standard timeout (default is 2 minutes)
export CLAUDE_STANDARD_TIMEOUT="120000"
```

**Replace `your-zai-token-here`, `your-minimax-token-here`, and `your-kimi-token-here` with your actual tokens!**

### 2. Reload Your Shell

```bash
source ~/.zshrc
```

## Installation

### Option 1: From GitHub (Recommended)

```bash
# Install from the GitHub repository
brew install sachicali/homebrew-claudeswap/claudeswap
```

### Option 2: Manual Homebrew Formula

1. Tap the repository:
```bash
brew tap sachicali/claudeswap
```

2. Install the formula:
```bash
brew install claudeswap
```

## Usage

```bash
# Switch to Z.ai (50min timeout)
claudeswap zai

# Switch to MiniMax (50min timeout, MiniMax-M2 model)
claudeswap minimax

# Switch to Kimi/Moonshot (50min timeout, 256K context)
claudeswap kimi

# Switch to standard Anthropic (2min timeout)
claudeswap standard

# Check current status
claudeswap status

# Restore from latest backup
claudeswap restore

# Test dynamic model mapping system
claudeswap test-models

# Performance benchmark and optimization
claudeswap benchmark

# Session management
claudeswap clear-sessions    # Clear all sessions
claudeswap backup-sessions   # Backup current sessions

# Show help
claudeswap help
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
- Base URL: `https://api.moonshot.cn/v1`
- Timeout: 3000000ms (50 minutes)
- Models: moonshot-v1-256k, moonshot-v1-128k, moonshot-v1-32k
- Supports Kimi K2 Thinking model (November 2025)
- Temperature mapping: API applies 0.6x multiplier automatically
- Uses your `CLAUDE_KIMI_AUTH_TOKEN`
- Context: Up to 256K tokens

### Standard Configuration
- Base URL: (removed/blank)
- Timeout: 120000ms (2 minutes) - customizable via `CLAUDE_STANDARD_TIMEOUT`
- Restores your original API key

## 🚀 New Features in v1.2.0

### Dynamic Model Mapping
- **Universal Model Support**: Automatically detects and maps any model type (sonnet, haiku, opus, GLM, MiniMax, Kimi)
- **Provider-Agnostic**: Seamlessly switch between Anthropic, MiniMax, GLM, and Kimi/Moonshot providers
- **Smart Detection**: Identifies model families and performance tiers
- **Future-Proof**: Handles new model releases automatically including Kimi K2 Thinking (Nov 2025)

### Session Compatibility
- **Fixes `claude --continue` Errors**: Resolves "Unknown Model" and "Invalid signature" issues
- **Session Transformation**: Automatically normalizes sessions for provider compatibility
- **Interactive Options**: Choose to transform, backup, or clear sessions when switching
- **Preserved History**: Maintain conversation continuity across providers

### Performance Optimization
- **Parallel Processing**: Multi-threaded session transformations
- **Smart Caching**: Model extraction cache with LRU eviction
- **Bulk Operations**: Optimized JSON processing for faster transformations
- **Performance Monitoring**: Built-in benchmarking and optimization recommendations

### Advanced Session Management
- **Session Analysis**: Discover all models in your current sessions
- **Selective Backup**: Backup sessions before provider switches
- **Progress Tracking**: Real-time progress for large session sets

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

- macOS or Linux
- `jq` (installable via Homebrew: `brew install jq`)
- Zsh shell (default on macOS) or Bash
- `GNU parallel` (optional, for performance optimization: `brew install parallel`)

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

# Standard
export CLAUDE_STANDARD_TIMEOUT="120000"  # 2 minutes
```

## Uninstallation

```bash
brew uninstall claudeswap
brew untap sachicali/claudeswap
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

## License

MIT
