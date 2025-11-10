# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0] - 2025-11-10

### Added
- **🎨 TUI Mode** - Complete interactive Text User Interface powered by Charmbracelet Gum
  - Interactive main menu with keyboard navigation
  - Provider selection with visual status indicators (✓ = configured, ○ = not configured)
  - Guided credential setup with password-masked input
  - Provider comparison table showing side-by-side details
  - Searchable model filter with type-to-filter capability
  - Beautiful styled output with borders and colors
  - Loading spinners for API calls and long operations
  - Confirmation prompts to prevent accidental actions
- **TUI Components** (7 modular files in lib/tui/)
  - `gum_utils.sh` - Gum dependency checking and installation instructions
  - `main_menu.sh` - Main TUI loop and menu handler
  - `provider_select.sh` - Interactive provider selection
  - `credential_input.sh` - Secure credential input with validation
  - `comparison_table.sh` - Provider comparison table view
  - `model_filter.sh` - Interactive model browsing and filtering
- **New Commands**
  - `claudeswap` (no args) - Enter TUI mode if Gum installed (new default behavior)
  - `claudeswap tui` / `--tui` - Explicitly enter TUI mode
  - `claudeswap --no-tui <command>` - Force CLI mode
- **Graceful Degradation** - Falls back to CLI mode if Gum not installed
- **Gum Installation Instructions** - Automatic display when TUI requested without Gum

### Changed
- **Default Behavior** - Running `claudeswap` with no arguments now enters TUI mode (if Gum installed)
- **Help Output** - Updated to include TUI commands and show TUI availability status
- **Version Output** - Now displays TUI mode availability
- **lib/constants.sh** - Added TUI configuration constants (colors, borders, limits)

### Inspired By
- OpenCode (https://github.com/opencode-ai/opencode) - Interactive TUI design, multi-provider support
- just-every/code (https://github.com/just-every/code) - Unified settings, card-based rendering

## [1.3.0] - 2025-11-10

### Added
- **Kimi/Moonshot Provider Support** - Full integration with Moonshot AI's Kimi models
  - Support for moonshot-v1-256k (256K token context)
  - Support for moonshot-v1-128k, moonshot-v1-32k, moonshot-v1-8k
  - Kimi K2 Thinking model (November 2025 release)
  - Temperature mapping (0.6x multiplier) handled automatically
  - API endpoint: `https://api.moonshot.cn/v1`
- **Comprehensive Error Handling** - All curl operations now validate responses
- **Input Validation** - Token length checks, whitespace detection, format validation
- **Security Hardening** - Bash safety directives (`set -euo pipefail`) in all files
- **File Existence Checks** - Validate all library files before sourcing
- **API Timeout Constants** - Centralized configuration in constants.sh

### Changed
- **Major Refactoring** - Split 230-line `fetch_available_models()` into 7 focused functions
  - `fetch_openrouter_data()` - Shared OpenRouter API fetching (18 lines)
  - `fetch_standard_models()` - Anthropic model fetching (39 lines)
  - `fetch_minimax_models()` - MiniMax model fetching (20 lines)
  - `fetch_kimi_models()` - Kimi/Moonshot model fetching (45 lines)
  - `fetch_glm_models()` - GLM/Z.ai model fetching (66 lines)
  - `deduplicate_models()` - Model deduplication (38 lines)
- **NASA's 10 Rules Compliance** - 100% compliance achieved
  - All functions under 70 lines (NASA Rule 4)
  - Fixed loop bounds on all iterations (NASA Rule 2)
  - Comprehensive return value checks (NASA Rule 7)
- **TIGERSTYLE Compliance** - Production-ready code quality
  - Simple control flow (no recursion)
  - Fixed limits on everything
  - Minimal abstractions
  - Zero technical debt

### Fixed
- **Critical Security Issues** (3 injection vulnerabilities eliminated)
  - Shell injection in token writes (lib/credentials.sh:76)
  - JSON injection in jq commands (claudeswap:213-231)
  - Proper escaping using `printf` and `jq --arg`
- **Unbounded Loops** - Added MAX_INTERACTIVE_ATTEMPTS=50 to all interactive loops
- **Token Masking Edge Case** - Safe masking for tokens < 14 characters
- **Unbound Variables** - All optional variables use `${VAR:-}` syntax
- **Race Conditions** - Atomic temp file operations using `mktemp` and cleanup traps
- **File Permissions** - Proper checks before file operations

### Security
- All user input now validated before use
- Temporary files use `mktemp` instead of predictable names
- Cleanup traps prevent file leaks
- All network operations have error handling
- Token injection vulnerabilities eliminated

## [1.2.8] - 2025-11-09

### Added
- Dynamic model mapping across providers
- Session backup and restore functionality
- Performance optimizations with caching

### Changed
- Improved session compatibility checks
- Enhanced model detection logic

### Fixed
- Session continuation errors across providers
- Model mapping edge cases

## [1.2.0] - 2025-11-08

### Added
- MiniMax provider support
- Z.ai / GLM provider support
- Interactive credential setup
- Model family detection

### Changed
- Modular architecture with separated concerns
- Improved error messages

## [1.0.0] - 2025-11-01

### Added
- Initial release
- Basic provider switching (Standard Anthropic only)
- Settings file management
- Backup functionality

---

## Categories

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for security-related changes
