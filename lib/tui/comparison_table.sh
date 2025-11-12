#!/usr/bin/env bash

# TUI Provider Comparison Table
# Single Responsibility: Display provider comparison in table format

# Source guard
[[ -n "${_COMPARISON_TABLE_LOADED:-}" ]] && return 0
readonly _COMPARISON_TABLE_LOADED=1

# Bash safety: exit on error, undefined vars, pipe failures
set +e
set -u

# NASA Rule 7: Check file existence before sourcing
if [[ ! -f "${CLAUDE_SWAP_BASE_DIR}/lib/tui/tui_common.sh" ]]; then
    echo "ERROR: Required tui_common.sh not found" >&2
    exit 1
fi

source "${CLAUDE_SWAP_BASE_DIR}/lib/tui/tui_common.sh"

# Build provider comparison data
build_comparison_data() {
    local -a providers=("standard" "zai" "kimi" "minimax")
    local -a rows=()

    # Header row
    rows+=("Provider|Status|Base URL|Timeout|Features")

    # NASA Rule 2: Fixed bounds
    local provider_count=0

    for provider in "${providers[@]}"; do
        if [[ $provider_count -ge $MAX_PROVIDERS_DISPLAY ]]; then
            break
        fi

        local status="○ Not Configured"
        local base_url=""
        local timeout=""
        local features=""

        case "$provider" in
            "standard")
                base_url="api.anthropic.com"
                timeout="${STANDARD_TIMEOUT}ms"
                features="Official API"
                [[ -n "${ANTHROPIC_API_KEY:-}" ]] && status="✓ Configured"
                ;;
            "zai")
                base_url="${ZAI_BASE_URL#https://}"
                timeout="${ZAI_TIMEOUT}ms"
                features="GLM Models, API Compatible"
                [[ -n "${ZAI_AUTH_TOKEN:-}" ]] && status="✓ Configured"
                ;;
            "kimi")
                base_url="${KIMI_BASE_URL#https://}"
                timeout="${KIMI_TIMEOUT}ms"
                features="Moonshot AI, 256K Context"
                [[ -n "${KIMI_AUTH_TOKEN:-}" ]] && status="✓ Configured"
                ;;
            "minimax")
                base_url="${MINIMAX_BASE_URL#https://}"
                timeout="${MINIMAX_TIMEOUT}ms"
                features="MiniMax Models"
                [[ -n "${MINIMAX_AUTH_TOKEN:-}" ]] && status="✓ Configured"
                ;;
        esac

        rows+=("$provider|$status|$base_url|$timeout|$features")
        provider_count=$((provider_count + 1))
    done

    printf '%s\n' "${rows[@]}"
}

# Show provider comparison table
show_provider_comparison() {
    # Display styled header
    gum style \
        --border "$GUM_BORDER_STYLE" \
        --border-foreground "$GUM_PRIMARY_COLOR" \
        --padding "1 2" \
        --margin "1" \
        --align center \
        "Provider Comparison"

    # Build and display table
    local comparison_data
    comparison_data=$(build_comparison_data)

    echo "$comparison_data" | gum table \
        --border="$GUM_BORDER_STYLE" \
        --border.foreground="$GUM_PRIMARY_COLOR" \
        --widths="12,20,30,12,30"

    # Show current provider
    local current_provider
    current_provider=$(jq -r '.provider // "unknown"' "$SETTINGS_FILE" 2>/dev/null || echo "unknown")

    gum style \
        --foreground="$GUM_SUCCESS_COLOR" \
        --margin "1 0" \
        "Current Provider: $current_provider"

    # Pause for user
    gum spin --spinner dot --title "Press Ctrl+C to return to menu..." -- sleep 10

    return 0
}
