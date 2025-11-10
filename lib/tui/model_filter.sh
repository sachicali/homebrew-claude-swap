#!/usr/bin/env bash

# TUI Model Filter Handler
# Single Responsibility: Interactive model browsing and filtering

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# NASA Rule 7: Check file existence before sourcing
if [[ ! -f "${CLAUDE_SWAP_BASE_DIR}/lib/tui/gum_utils.sh" ]]; then
    echo "ERROR: Required gum_utils.sh not found" >&2
    exit 1
fi

source "${CLAUDE_SWAP_BASE_DIR}/lib/tui/gum_utils.sh"

# Show model filter with searchable list
show_model_filter_tui() {
    # Get current provider
    local current_provider
    current_provider=$(jq -r '.provider // "unknown"' "$SETTINGS_FILE" 2>/dev/null || echo "unknown")

    # Display styled header
    gum style \
        --border "$GUM_BORDER_STYLE" \
        --border-foreground "$GUM_PRIMARY_COLOR" \
        --padding "1 2" \
        --margin "1" \
        "Available Models for: $current_provider"

    # Fetch models with spinner
    local models
    models=$(gum spin \
        --spinner dot \
        --title "Fetching models..." \
        --show-output \
        -- fetch_available_models "$current_provider")

    if [[ -z "$models" ]]; then
        gum style \
            --foreground="$GUM_ERROR_COLOR" \
            "Error: No models found for $current_provider"
        return 1
    fi

    # Convert models to array
    local -a model_array=()
    local max_models=200  # NASA Rule 2: Fixed bound
    local model_count=0

    while IFS= read -r model; do
        if [[ $model_count -ge $max_models ]]; then
            break
        fi
        [[ -n "$model" ]] && model_array+=("$model")
        model_count=$((model_count + 1))
    done <<< "$models"

    if [[ ${#model_array[@]} -eq 0 ]]; then
        gum style \
            --foreground="$GUM_ERROR_COLOR" \
            "Error: No models available"
        return 1
    fi

    # Show filterable model list
    gum style \
        --foreground="$GUM_PRIMARY_COLOR" \
        "Found ${#model_array[@]} models. Use arrow keys to browse, type to filter."

    local selected_model
    selected_model=$(printf '%s\n' "${model_array[@]}" | \
        gum filter \
            --placeholder="Type to filter models..." \
            --height="$GUM_FILTER_HEIGHT" \
            --indicator.foreground="$GUM_PRIMARY_COLOR" \
            --match.foreground="$GUM_SUCCESS_COLOR")

    if [[ -n "$selected_model" ]]; then
        gum style \
            --border "$GUM_BORDER_STYLE" \
            --border-foreground="$GUM_SUCCESS_COLOR" \
            --padding "1 2" \
            --margin "1" \
            "Selected Model" \
            "" \
            "$selected_model"

        # Show model details if available
        local details
        details=$(get_model_details "$selected_model" "$current_provider" 2>/dev/null || echo "")

        if [[ -n "$details" ]]; then
            gum style \
                --foreground="$GUM_PRIMARY_COLOR" \
                "Details: $details"
        fi

        # Ask if user wants to copy to clipboard
        if gum confirm "Copy model name to clipboard?"; then
            # Try different clipboard commands
            if command -v pbcopy >/dev/null 2>&1; then
                echo -n "$selected_model" | pbcopy
                gum style --foreground="$GUM_SUCCESS_COLOR" "✓ Copied to clipboard"
            elif command -v xclip >/dev/null 2>&1; then
                echo -n "$selected_model" | xclip -selection clipboard
                gum style --foreground="$GUM_SUCCESS_COLOR" "✓ Copied to clipboard"
            elif command -v xsel >/dev/null 2>&1; then
                echo -n "$selected_model" | xsel --clipboard
                gum style --foreground="$GUM_SUCCESS_COLOR" "✓ Copied to clipboard"
            else
                gum style --foreground="$GUM_WARNING_COLOR" "No clipboard tool found (pbcopy/xclip/xsel)"
            fi
        fi
    fi

    return 0
}
