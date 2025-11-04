# Claude Swap - Setup Guide

## ⚠️ IMPORTANT: READ THIS FIRST!

This tool requires you to configure your own API credentials. **No credentials are included** in the public version.

---

## Quick Setup

### Step 1: Install the Tool

```bash
brew tap sachicali/claudeswap
brew install claudeswap
```

### Step 2: Get Your API Tokens

#### Standard Anthropic (Always Needed)
1. Go to: https://console.anthropic.com/
2. Sign in or create account
3. Navigate to "API Keys"
4. Click "Create Key"
5. Copy the key (starts with `sk-ant-api03-`)
6. This is your STANDARD token - keep it safe!

#### Z.ai (Optional - Only if you have access)
- Contact Z.ai for API access
- Get your API token from them
- Save it securely

#### MiniMax (Optional - Only if you have access)
- Contact MiniMax for API access
- Get your API token from them
- Save it securely

### Step 3: Configure Environment Variables

Edit your shell configuration file (`~/.zshrc` for zsh or `~/.bashrc` for bash):

```bash
# Add these lines:

# Z.ai Configuration (optional - only if you have access)
export CLAUDE_ZAI_AUTH_TOKEN="your-zai-token-here"
export CLAUDE_ZAI_BASE_URL="https://api.z.ai/api/anthropic"

# MiniMax Configuration (optional - only if you have access)
export CLAUDE_MINIMAX_AUTH_TOKEN="your-minimax-token-here"
export CLAUDE_MINIMAX_BASE_URL="https://api.minimax.io/anthropic"

# Customize timeouts (optional)
export CLAUDE_STANDARD_TIMEOUT="120000"    # 2 minutes (default)
export CLAUDE_ZAI_TIMEOUT="3000000"        # 50 minutes (default)
export CLAUDE_MINIMAX_TIMEOUT="3000000"    # 50 minutes (default)
```

**Important**: Replace `your-zai-token-here` and `your-minimax-token-here` with your actual tokens!

### Step 4: Reload Your Shell

```bash
source ~/.zshrc
```

### Step 5: Test

```bash
claudeswap status
```

You should see your current configuration. If you haven't set up tokens yet, you'll see warnings.

---

## Detailed Explanation

### What Are Environment Variables?

Environment variables are shell variables that persist across terminal sessions. They're stored in `~/.zshrc` or `~/.bashrc`.

### Where to Find Your Tokens

#### Standard Anthropic
- Visit: https://console.anthropic.com/
- Log in with your account
- Go to "API Keys" section
- Your key looks like: `sk-ant-api03-...`

#### Z.ai
- Visit: https://z.ai/manage-apikey/apikey-list
- Sign in or create account
- Navigate to API key management
- Create a new key

#### MiniMax
- Visit: https://platform.minimax.io/user-center/basic-information/interface-key
- Sign in or create account
- Navigate to interface key section
- Create a new key

### Security Best Practices

1. **Never share your tokens** - they're like passwords
2. **Don't commit tokens to Git** - keep them in `~/.zshrc` only
3. **Rotate tokens regularly** - regenerate and update
4. **Monitor usage** - check your API dashboards

### Troubleshooting

#### "Z.ai credentials not configured"
```bash
# Check if the variable is set
echo $CLAUDE_ZAI_AUTH_TOKEN

# If empty, update ~/.zshrc and run:
source ~/.zshrc
```

#### "jq not found"
```bash
# Install jq via Homebrew
brew install jq
```

#### "Token not working"
1. Verify the token is correct (no extra spaces)
2. Check the token hasn't expired
3. Ensure you reloaded: `source ~/.zshrc`
4. Try logging out and back in

### File Locations

**Settings file:**
```
~/.claude/settings.json
```

**Backups:**
```
~/.claude/backups/settings_*.json
```

**Your shell config:**
```
~/.zshrc  (zsh - default on macOS)
~/.bashrc (bash)
```

---

## Usage Examples

### Check Your Current Configuration

```bash
claudeswap status
```

### Switch to Z.ai (if you have access)

```bash
claudeswap zai
```

### Switch to MiniMax (if you have access)

```bash
claudeswap minimax
```

### Switch to Standard Anthropic

```bash
claudeswap standard
```

### Restore from Backup

```bash
claudeswap restore
```

---

## What Gets Changed

When you switch configurations, the tool updates these settings in `~/.claude/settings.json`:

- `ANTHROPIC_BASE_URL` - Changes API endpoint
- `ANTHROPIC_AUTH_TOKEN` - Changes API token
- `API_TIMEOUT_MS` - Changes timeout
- Model settings (for MiniMax)

### Automatic Backups

Before every change, a timestamped backup is created:
```
~/.claude/backups/settings_20251102_143022.json
```

You can restore any backup manually or with:
```bash
claudeswap restore
```

---

## Environment Variables Reference

All environment variables are optional (except your actual tokens):

```bash
# Z.ai
export CLAUDE_ZAI_AUTH_TOKEN="..."      # Required for Z.ai features
export CLAUDE_ZAI_BASE_URL="..."        # Optional (default provided)
export CLAUDE_ZAI_TIMEOUT="..."         # Optional (default: 3000000)

# MiniMax
export CLAUDE_MINIMAX_AUTH_TOKEN="..."  # Required for MiniMax features
export CLAUDE_MINIMAX_BASE_URL="..."    # Optional (default provided)
export CLAUDE_MINIMAX_TIMEOUT="..."     # Optional (default: 3000000)

# Standard
export CLAUDE_STANDARD_TIMEOUT="..."    # Optional (default: 120000)
```

---

## Need Help?

Run:
```bash
claudeswap help
```

Or check the examples:
```bash
cat /opt/homebrew/share/doc/claudeswap/example-configs.md
```

---

## Security Notes

- **This tool is safe** - it only reads your environment variables
- **Tokens stay local** - never transmitted to our servers
- **All operations are local** - your data stays on your machine
- **Open source** - you can inspect the code

The public version contains NO hardcoded credentials. You must provide your own!
