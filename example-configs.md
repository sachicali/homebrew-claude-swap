# Example Configurations

This file shows example configurations for different Claude setups.

## Configuration File Location

`~/.claude/settings.json`

## Environment Variable Setup

**BEFORE using this tool**, configure your credentials in `~/.zshrc`:

```bash
# For Z.ai access (if you have it)
export CLAUDE_ZAI_AUTH_TOKEN="your-zai-token-here"
export CLAUDE_ZAI_BASE_URL="https://api.z.ai/api/anthropic"

# For MiniMax access (if you have it)
export CLAUDE_MINIMAX_AUTH_TOKEN="your-minimax-token-here"
export CLAUDE_MINIMAX_BASE_URL="https://api.minimax.io/anthropic"

# Reload your shell
source ~/.zshrc
```

Then use the tool:
```bash
claude-swap zai       # Switch to Z.ai
claude-swap minimax   # Switch to MiniMax
claude-swap standard  # Switch to standard
claude-swap status    # Check config
```

## Example: Standard Anthropic Configuration

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "sk-ant-api03-your-token-here",
    "API_TIMEOUT_MS": "120000"
  }
}
```

## Example: Z.ai Configuration

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "your-zai-token-here",
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "API_TIMEOUT_MS": "3000000"
  }
}
```

## Example: MiniMax Configuration

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.minimax.io/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "your-minimax-token-here",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1,
    "ANTHROPIC_MODEL": "MiniMax-M2",
    "ANTHROPIC_SMALL_FAST_MODEL": "MiniMax-M2",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "MiniMax-M2",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "MiniMax-M2",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "MiniMax-M2"
  }
}
```

## Backup Files

Backups are automatically created in:
`~/.claude/backups/settings_YYYYMMDD_HHMMSS.json`

You can manually restore from any backup:
```bash
cp ~/.claude/backups/settings_20251102_143022.json ~/.claude/settings.json
```

Or use the built-in restore command:
```bash
claude-swap restore
```

## Getting Your API Tokens

### Standard Anthropic
1. Go to: https://console.anthropic.com/
2. Sign in or create account
3. Navigate to API Keys
4. Create a new key
5. Copy the key (starts with `sk-ant-api03-`)

### Z.ai
Contact Z.ai directly for API access and token.

### MiniMax
Contact MiniMax directly for API access and token.

## Security Notes

- **Never share your API tokens** with anyone
- **Don't commit tokens to Git** - keep them in environment variables only
- **This tool stores tokens only locally** - not transmitted anywhere
- **Rotate tokens regularly** for security

## Customization

You can customize timeouts and URLs:

```bash
# In your ~/.zshrc
export CLAUDE_ZAI_TIMEOUT="6000000"     # 100 minutes
export CLAUDE_MINIMAX_TIMEOUT="600000"  # 10 minutes
export CLAUDE_STANDARD_TIMEOUT="300000" # 5 minutes
```
