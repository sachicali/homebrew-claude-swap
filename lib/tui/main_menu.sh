#!/usr/bin/env bash

# TUI Main Menu Handler
# Single Responsibility: Display and handle main menu interactions

# Source guard
[[ -n "${_MAIN_MENU_LOADED:-}" ]] && return 0
readonly _MAIN_MENU_LOADED=1

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# NASA Rule 7: Check file existence before sourcing
if [[ ! -f "${CLAUDE_SWAP_BASE_DIR}/lib/tui/tui_common.sh" ]]; then
    echo "ERROR: Required tui_common.sh not found" >&2
    exit 1
fi

source "${CLAUDE_SWAP_BASE_DIR}/lib/tui/tui_common.sh"

# Display TUI main menu and handle selection (NASA Rule 4: <70 lines)
show_main_menu() {
    local -a menu_items=(
        "🔄 Switch Provider"
        "🔧 Setup Credentials"
        "📊 Compare Providers"
        "🧪 Test Models"
        "📈 View Status"
        "💾 Manage Sessions"
        "📜 View History"
        "❌ Exit"
    )

    # NASA Rule 2: Fixed bound on menu items
    if [[ ${#menu_items[@]} -gt $MAX_TUI_MENU_ITEMS ]]; then
        log_error_tui "Menu items exceed maximum"
        return 1
    fi

    # Display styled header
    gum style \
        --border "$GUM_BORDER_STYLE" \
        --border-foreground "$GUM_PRIMARY_COLOR" \
        --padding "1 2" \
        --margin "1" \
        --align center \
        "ClaudeSwap - TUI Mode" \
        "" \
        "Select an option:"

    # Show menu with gum choose
    local choice
    choice=$(printf '%s\n' "${menu_items[@]}" | \
        gum choose \
            --height="$GUM_CHOOSE_HEIGHT" \
            --cursor.foreground="$GUM_PRIMARY_COLOR" \
            --selected.foreground="$GUM_SUCCESS_COLOR")

    echo "$choice"
}

# Main TUI loop (NASA Rule 4: <70 lines)
run_tui_main_loop() {
    local iteration=0

    # NASA Rule 2: Fixed upper bound
    while [[ $iteration -lt $MAX_TUI_ITERATIONS ]]; do
        iteration=$((iteration + 1))

        local choice
        choice=$(show_main_menu) || {
            log_error_tui "Failed to show main menu"
            return 1
        }

        # Handle empty/cancelled selection (user pressed ESC or Ctrl+C)
        if [[ -z "$choice" ]]; then
            gum style \
                --foreground="$GUM_WARNING_COLOR" \
                "Selection cancelled. Exiting..."
            return 0
        fi

        case "$choice" in
            "🔄 Switch Provider")
                # Call provider selection TUI (pre-loaded)
                if declare -f show_provider_selection_tui >/dev/null 2>&1; then
                    show_provider_selection_tui || log_error_tui "Provider selection failed"
                else
                    log_error_tui "Provider selection function not available"
                fi
                # Pause to let user see result before returning to menu
                gum spin --spinner dot --title "Press any key to continue..." -- sleep 2
                ;;
            "🔧 Setup Credentials")
                # Call credential setup TUI (pre-loaded)
                if declare -f show_credential_setup_tui >/dev/null 2>&1; then
                    show_credential_setup_tui || log_error_tui "Credential setup failed"
                else
                    log_error_tui "Credential setup function not available"
                fi
                # Pause to let user see result before returning to menu
                gum spin --spinner dot --title "Press any key to continue..." -- sleep 2
                ;;
            "📊 Compare Providers")
                # Call comparison table (pre-loaded)
                if declare -f show_provider_comparison >/dev/null 2>&1; then
                    show_provider_comparison || log_error_tui "Provider comparison failed"
                else
                    log_error_tui "Provider comparison function not available"
                fi
                # Pause to let user see result before returning to menu
                gum spin --spinner dot --title "Press any key to continue..." -- sleep 3
                ;;
            "🧪 Test Models")
                # Call model filter (pre-loaded)
                if declare -f show_model_filter_tui >/dev/null 2>&1; then
                    show_model_filter_tui || log_error_tui "Model filter failed"
                else
                    log_error_tui "Model filter function not available"
                fi
                # Pause to let user see result before returning to menu
                gum spin --spinner dot --title "Press any key to continue..." -- sleep 2
                ;;
            "📈 View Status")
                tui_handle_status || log_error_tui "Status display failed"
                gum spin --spinner dot --title "Press any key to continue..." -- sleep 3
                ;;
            "💾 Manage Sessions")
                # Show session management submenu
                log_info_tui "Session management menu (coming soon)"
                gum spin --spinner dot --title "Press any key to continue..." -- sleep 2
                ;;
            "📜 View History")
                # Call history viewer
                if [[ -f "${CLAUDE_SWAP_BASE_DIR}/lib/tui/history.sh" ]]; then
                    source "${CLAUDE_SWAP_BASE_DIR}/lib/tui/history.sh"
                    show_history_tui || log_error_tui "History view failed"
                else
                    log_warning_tui "History view not yet implemented"
                fi
                # Pause to let user see result before returning to menu
                gum spin --spinner dot --title "Press any key to continue..." -- sleep 2
                ;;
            "❌ Exit")
                gum style \
                    --foreground="$GUM_SUCCESS_COLOR" \
                    "Thank you for using ClaudeSwap!"
                return 0
                ;;
            *)
                # This should not happen with gum choose, but if it does, just continue
                # instead of showing an error, as it's likely a transient issue
                continue
                ;;
        esac
    done

    log_error_tui "Maximum iterations reached in TUI loop"
    return 1
}
