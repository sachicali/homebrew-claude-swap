#compdef claudeswap

# zsh completion for claudeswap

local cur prev

cur="${words[CURRENT]}"
prev="${words[CURRENT-1]}"

_commands=(
  "zai:Switch to Z.ai configuration"
  "minimax:Switch to MiniMax configuration"
  "mm:Switch to MiniMax configuration (short)"
  "standard:Switch to standard Anthropic configuration"
  "std:Switch to standard Anthropic configuration (short)"
  "status:Show current configuration status"
  "st:Show current configuration status (short)"
  "restore:Restore from latest backup"
  "help:Show help message"
  "test-models:Test dynamic model mapping system"
  "benchmark:Performance benchmark and optimization"
  "clear-sessions:Clear all sessions"
  "backup-sessions:Backup current sessions"
)

_describe "command" _commands

case "$cur" in
  -*)
    _arguments \
      '(-h|--help)'{'-h','--help'}'[Show help message]' \
      '(-v|--version)'{'-v','--version'}'[Show version information]'
    ;;
esac
