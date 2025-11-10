#!/usr/bin/env bash

# TUI Main Menu Handler
# Single Responsibility: Display and handle main menu interactions

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# NASA Rule 7: Check file existence before sourcing
if [[ ! -f "${CLAUDE_SWAP_BASE_DIR}/lib/tui/gum_utils.sh" ]]; then
    echo "ERROR: Required gum_utils.sh not found" >&2
    exit 1
fi

source "${CLAUDE_SWAP_BASE_DIR}/lib/tui/gum_utils.sh"

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
        log_error "Menu items exceed maximum ($MAX_TUI_MENU_ITEMS)"
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
            log_error "Failed to show main menu"
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
                # Call provider selection TUI
                if [[ -f "${CLAUDE_SWAP_BASE_DIR}/lib/tui/provider_select.sh" ]]; then
                    source "${CLAUDE_SWAP_BASE_DIR}/lib/tui/provider_select.sh"
                    show_provider_selection_tui || log_error "Provider selection failed"
                else
                    log_warning "Provider selection TUI not yet implemented"
                fi
                ;;
            "🔧 Setup Credentials")
                # Call credential setup TUI
                if [[ -f "${CLAUDE_SWAP_BASE_DIR}/lib/tui/credential_input.sh" ]]; then
                    source "${CLAUDE_SWAP_BASE_DIR}/lib/tui/credential_input.sh"
                    show_credential_setup_tui || log_error "Credential setup failed"
                else
                    log_warning "Credential setup TUI not yet implemented"
                fi
                ;;
            "📊 Compare Providers")
                # Call comparison table
                if [[ -f "${CLAUDE_SWAP_BASE_DIR}/lib/tui/comparison_table.sh" ]]; then
                    source "${CLAUDE_SWAP_BASE_DIR}/lib/tui/comparison_table.sh"
                    show_provider_comparison || log_error "Provider comparison failed"
                else
                    log_warning "Provider comparison not yet implemented"
                fi
                ;;
            "🧪 Test Models")
                # Call model filter
                if [[ -f "${CLAUDE_SWAP_BASE_DIR}/lib/tui/model_filter.sh" ]]; then
                    source "${CLAUDE_SWAP_BASE_DIR}/lib/tui/model_filter.sh"
                    show_model_filter_tui || log_error "Model filter failed"
                else
                    handle_test_models || log_error "Test models failed"
                fi
                ;;
            "📈 View Status")
                handle_status || log_error "Status display failed"
                gum spin --spinner dot --title "Press any key to continue..." -- sleep 3
                ;;
            "💾 Manage Sessions")
                # Show session management submenu
                log_info "Session management menu (coming soon)"
                gum spin --spinner dot --title "Press any key to continue..." -- sleep 2
                ;;
            "📜 View History")
                # Call history viewer
                if [[ -f "${CLAUDE_SWAP_BASE_DIR}/lib/tui/history.sh" ]]; then
                    source "${CLAUDE_SWAP_BASE_DIR}/lib/tui/history.sh"
                    show_history_tui || log_error "History view failed"
                else
                    log_warning "History view not yet implemented"
                fi
                ;;
            "❌ Exit")
                gum style \
                    --foreground="$GUM_SUCCESS_COLOR" \
                    "Thank you for using ClaudeSwap!"
                return 0
                ;;
            *)
                log_error "Invalid menu selection: $choice"
                ;;
        esac
    done

    log_error "Maximum iterations reached in TUI loop"
    return 1
}
