# TUI Transformation Design

## Research Summary

### OpenCode Best Features Analysis

**Source:** https://github.com/opencode-ai/opencode

#### Features to Integrate:
1. **Interactive TUI with Bubble Tea** - Full-screen interactive interface
2. **Multi-Provider Support (75+ providers)** - Already have 4, can expand
3. **Session Management with Persistence** - SQLite storage for session history
4. **Tool Integration** - Execute commands and modify code interactively
5. **File Change Tracking** - Track what files were modified per provider
6. **LSP Integration** - Code intelligence (future enhancement)

#### Applicable to ClaudeSwap:
- ✅ Multi-provider support (already have standard, zai, minimax, kimi)
- ✅ Session management (already have backup/restore, can add persistence)
- ✅ File tracking (can track provider switches and settings changes)
- ⚠️ LSP integration (out of scope for settings manager)

### just-every/code Best Features Analysis

**Source:** https://github.com/just-every/code

#### Features to Integrate:
1. **Auto Drive** - Task planning and agent coordination
2. **Unified Settings** - Single configuration interface
3. **Card-Based Activity Rendering** - Visual representation of operations
4. **Multi-Agent Orchestration** - Mix and match different models
5. **Consensus Planning** - Use multiple models for decision making
6. **Turbocharged Performance** - Optimized for speed

#### Applicable to ClaudeSwap:
- ✅ Unified settings (perfect for our use case)
- ✅ Card-based rendering (great for provider comparison)
- ✅ Multi-provider orchestration (can test models across providers)
- ⚠️ Auto Drive (out of scope - we're a settings manager, not a coding agent)
- ⚠️ Consensus planning (interesting future feature)

## TUI Framework Selection

### Charmbracelet Gum

**Chosen:** ✅ Gum for shell script integration

**Rationale:**
- Designed specifically for bash/shell scripts
- No need to rewrite in Go
- Easy to integrate incrementally
- Maintains TIGERSTYLE simplicity
- All functions can stay under 70 lines (NASA Rule 4)

**Key Commands to Use:**
1. `gum choose` - Provider/model selection menus
2. `gum filter` - Searchable model lists
3. `gum input` - Credential/token input with validation
4. `gum confirm` - Action confirmations
5. `gum spin` - Loading indicators for API calls
6. `gum style` - Styled output with borders/colors
7. `gum table` - Provider/model comparison tables
8. `gum log` - Enhanced logging with levels

## Architecture Design

### Current Architecture (CLI Mode)
```
claudeswap <command> [args]
├── help              # Show help
├── status            # Show current config
├── version           # Show version
├── test-models       # List models
├── set <provider>    # Switch provider
├── setup             # Interactive credential setup
├── backup            # Backup sessions
└── clear             # Clear sessions
```

### New Architecture (TUI Mode)
```
claudeswap [--tui]    # Enter TUI mode (default if no args)
├── Main Menu (gum choose)
│   ├── 🔄 Switch Provider        → Provider Selection TUI
│   ├── 🔧 Setup Credentials      → Credential Setup TUI
│   ├── 📊 Compare Providers      → Provider Comparison Table
│   ├── 🧪 Test Models            → Model List with Filter
│   ├── 📈 View Status            → Styled Status Display
│   ├── 💾 Manage Sessions        → Session Management Menu
│   ├── 📜 View History           → Session History (new feature)
│   └── ❌ Exit
│
├── Provider Selection TUI
│   ├── gum filter with provider list
│   ├── Show current provider highlighted
│   ├── Preview: Show provider details on selection
│   └── gum confirm before switching
│
├── Credential Setup TUI
│   ├── gum choose provider
│   ├── gum input for token (with masking)
│   ├── gum input for optional model override
│   ├── gum confirm to save to .zshrc
│   └── gum spin while validating
│
├── Provider Comparison Table
│   ├── gum table with columns:
│   │   ├── Provider
│   │   ├── Status (configured/not configured)
│   │   ├── Model Count
│   │   ├── Base URL
│   │   └── Features
│   └── Color-coded status indicators
│
├── Model List with Filter
│   ├── gum filter on available models
│   ├── Show context length + pricing
│   ├── Multi-select capability
│   └── Export selection to file
│
└── Session History (NEW)
    ├── SQLite database: ~/.claude/history.db
    ├── Track: timestamp, provider, model, action
    ├── gum table view with sorting
    └── gum filter for searching history
```

### Backward Compatibility
```bash
# Legacy CLI commands still work:
claudeswap help           # Traditional help
claudeswap status         # Traditional status
claudeswap set kimi       # Direct provider switch (non-interactive)

# New TUI mode:
claudeswap                # Enter TUI main menu (new default)
claudeswap --tui          # Explicit TUI mode
claudeswap tui            # Alternative command
```

## Implementation Plan

### Phase 1: Foundation (P0)
1. Add Gum dependency check function
2. Create TUI mode detection
3. Implement basic main menu with gum choose
4. Add styled output for existing commands

### Phase 2: Interactive Selection (P1)
5. Convert provider selection to gum filter
6. Add interactive credential setup with gum input
7. Add confirmation prompts with gum confirm
8. Add loading spinners for API calls

### Phase 3: Enhanced Features (P2)
9. Create provider comparison table
10. Add model filter with preview
11. Implement styled borders and colors
12. Add session history tracking

### Phase 4: Polish (P3)
13. Add keyboard shortcuts
14. Improve error messages with gum log
15. Add help tooltips
16. Performance optimization

## File Structure Changes

### New Files to Create:
```
lib/tui/
├── main_menu.sh          # TUI main menu handler (< 70 lines)
├── provider_select.sh    # Interactive provider selection (< 70 lines)
├── credential_input.sh   # Interactive credential setup (< 70 lines)
├── model_filter.sh       # Interactive model filtering (< 70 lines)
├── comparison_table.sh   # Provider comparison view (< 70 lines)
├── history.sh            # Session history tracking (< 70 lines)
└── gum_utils.sh          # Gum helper functions (< 70 lines)
```

### Modified Files:
```
claudeswap                # Add TUI mode detection and routing
lib/constants.sh          # Add TUI-related constants
lib/logging.sh            # Integrate gum log for styled output
README.md                 # Document TUI mode and Gum installation
```

### New Constants (lib/constants.sh):
```bash
# TUI Configuration
readonly HISTORY_DB="${CLAUDE_CONFIG_DIR}/history.db"
readonly TUI_MODE="${CLAUDESWAP_TUI_MODE:-auto}"  # auto, always, never
readonly GUM_REQUIRED_VERSION="0.13.0"

# Gum Styling
readonly GUM_CHOOSE_HEIGHT="10"
readonly GUM_FILTER_HEIGHT="15"
readonly GUM_BORDER_STYLE="rounded"
readonly GUM_PRIMARY_COLOR="#00BFFF"
readonly GUM_SUCCESS_COLOR="#00FF00"
readonly GUM_ERROR_COLOR="#FF0000"
readonly GUM_WARNING_COLOR="#FFFF00"
```

## NASA's 10 Rules Compliance

✅ All new TUI functions will be < 70 lines
✅ All loops will have fixed bounds
✅ No dynamic memory allocation (bash arrays only)
✅ Simple control flow (no recursion)
✅ All return values checked
✅ Input validation on all user input
✅ Minimal variable scope
✅ Error handling with set -euo pipefail

## TIGERSTYLE Compliance

✅ Simple control flow - Each TUI function does one thing
✅ Fixed limits - All menus bounded, history table limited
✅ Minimal abstractions - Thin wrappers around Gum commands
✅ Zero technical debt - Clean, documented, tested

## Security Considerations

### Gum Dependency:
- Check Gum installation before TUI mode
- Provide clear installation instructions if missing
- Graceful fallback to CLI mode if Gum unavailable

### Token Input:
- Use `gum input --password` for token entry
- Continue to validate and mask tokens
- No tokens in shell history (use `gum input` instead of read)

### History Database:
- SQLite database with restrictive permissions (600)
- No sensitive data stored (no tokens, only metadata)
- Automatic cleanup of old entries (> 90 days)

## User Experience Improvements

### Before (CLI):
```bash
$ claudeswap setup
Please select a provider:
1) Standard Anthropic API
2) Z.ai / GLM
3) Kimi / Moonshot
4) MiniMax

Enter choice (1-4): 3
Enter your Kimi auth token: [user types blindly]
Save to ~/.zshrc? (y/n): y
✓ Credentials configured
```

### After (TUI):
```bash
$ claudeswap

╭─────────────────────────────────────╮
│      ClaudeSwap - Main Menu         │
├─────────────────────────────────────┤
│  🔄 Switch Provider                 │
│  🔧 Setup Credentials               │
│  📊 Compare Providers               │
│  🧪 Test Models                     │
│  📈 View Status                     │
│  💾 Manage Sessions                 │
│  📜 View History                    │
│  ❌ Exit                            │
╰─────────────────────────────────────╯

> 🔧 Setup Credentials

╭─────────────────────────────────────╮
│      Select Provider                │
├─────────────────────────────────────┤
│  Standard Anthropic API ✓           │
│  Z.ai / GLM ✓                       │
│> Kimi / Moonshot                    │
│  MiniMax                            │
╰─────────────────────────────────────╯

┃ Enter Kimi Auth Token: ******************
┃
┃ Save to ~/.zshrc? ● Yes ○ No

⠋ Validating credentials...

✓ Kimi credentials configured successfully!
```

## Implementation Timeline

### Week 1: Foundation
- Day 1-2: Gum integration and main menu
- Day 3-4: Provider selection TUI
- Day 5: Testing and refinement

### Week 2: Interactive Features
- Day 1-2: Credential input TUI
- Day 3-4: Model filter with preview
- Day 5: Provider comparison table

### Week 3: Advanced Features
- Day 1-2: Session history tracking
- Day 3-4: Styled output and colors
- Day 5: Documentation and polish

## Success Metrics

1. **Usability:** All operations achievable in ≤3 clicks/selections
2. **Performance:** All menus render in <100ms
3. **Compatibility:** 100% backward compatibility with CLI mode
4. **Code Quality:** All functions <70 lines, 100% NASA compliance
5. **Documentation:** Complete TUI guide with screenshots/GIFs

## Future Enhancements (Post-TUI Launch)

1. **Multi-Provider Testing:** Test same prompt across all providers simultaneously
2. **Cost Calculator:** Estimate costs based on token usage
3. **Model Recommendations:** Suggest best model for task type
4. **Configuration Profiles:** Switch between preset configurations
5. **Benchmark Mode:** Compare model performance across providers
6. **Export/Import:** Share configurations as JSON files

---

**Document Version:** 1.0
**Created:** November 10, 2025
**Status:** Design Complete, Ready for Implementation
