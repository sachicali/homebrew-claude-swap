#!/usr/bin/env bash

# Model fetching utilities
# Single Responsibility: Fetch available models from different providers

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# NASA Rule 7: Check file existence before sourcing
if [[ ! -f "${CLAUDE_SWAP_BASE_DIR}/lib/logging.sh" ]] || [[ ! -f "${CLAUDE_SWAP_BASE_DIR}/lib/utils/formatter.sh" ]]; then
    echo "ERROR: Required library files not found" >&2
    exit 1
fi

source "${CLAUDE_SWAP_BASE_DIR}/lib/logging.sh"
source "${CLAUDE_SWAP_BASE_DIR}/lib/utils/formatter.sh"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Fetch OpenRouter model data (shared helper)
# NASA Rule 7: Check curl return value
fetch_openrouter_data() {
    local openrouter_data=""

    if ! command -v curl >/dev/null 2>&1; then
        echo ""
        return 1
    fi

    # NASA Rule 7: Check curl exit status
    if openrouter_data=$(curl -s --max-time "$OPENROUTER_TIMEOUT" \
        "https://openrouter.ai/api/v1/models" 2>/dev/null | \
        jq -r '.data[] | "\(.id)|\(.context_length)|\(.pricing.prompt)|\(.pricing.completion)"' 2>/dev/null); then
        echo "$openrouter_data"
        return 0
    else
        log_warning "Failed to fetch OpenRouter data"
        echo ""
        return 1
    fi
}

# Deduplicate model list (NASA Rule 2: Fixed bounds)
# Bash 3.2 compatible - uses eval instead of nameref
deduplicate_models() {
    local array_name="$1"
    local unique_models=()
    local unique_count=0
    local model_idx=0

    # Use eval to access array by name (bash 3.2 compatible)
    local input_size
    eval "input_size=\${#${array_name}[@]}"

    if [[ $input_size -eq 0 ]]; then
        return 0
    fi

    local idx=0
    while [[ $idx -lt $input_size ]]; do
        if [[ $model_idx -ge $MAX_FETCH_MODELS ]] || [[ $unique_count -ge $MAX_UNIQUE_MODELS ]]; then
            break
        fi

        local model
        eval "model=\${${array_name}[$idx]}"

        local found=0
        local existing_idx=0
        for existing in "${unique_models[@]}"; do
            if [[ $existing_idx -ge $MAX_UNIQUE_MODELS ]]; then
                break
            fi
            if [[ "$existing" == "$model" ]]; then
                found=1
                break
            fi
            existing_idx=$((existing_idx + 1))
        done

        if [[ $found -eq 0 ]]; then
            unique_models+=("$model")
            unique_count=$((unique_count + 1))
        fi
        model_idx=$((model_idx + 1))
        idx=$((idx + 1))
    done

    printf '%s\n' "${unique_models[@]}"
}

# ============================================================================
# PROVIDER-SPECIFIC FETCH FUNCTIONS
# ============================================================================

# Fetch Standard Anthropic models (NASA Rule 4: <60 lines)
fetch_standard_models() {
    local openrouter_models="$1"
    local models=()

    # Extract from OpenRouter
    if [[ -n "$openrouter_models" ]]; then
        while IFS='|' read -r model_id context_length prompt_price completion_price; do
            if [[ "$model_id" == anthropic/* ]]; then
                local clean_model="${model_id#anthropic/}"
                case "$clean_model" in
                    "claude-sonnet-4.5") models+=("claude-sonnet-4-5-20250929") ;;
                    "claude-haiku-4.5") models+=("claude-haiku-4-5-20251001") ;;
                    "claude-opus-4.1") models+=("claude-opus-4.1") ;;
                    "claude-opus-4") models+=("claude-opus-4") ;;
                    *) models+=("$clean_model") ;;
                esac
            fi
        done <<< "$openrouter_models"
    fi

    # Try Anthropic docs as backup
    if [[ ${#models[@]} -eq 0 ]] && command -v curl >/dev/null 2>&1; then
        local docs_models
        if docs_models=$(curl -s --max-time "$PROVIDER_API_TIMEOUT" \
            "https://docs.anthropic.com/en/api/models" 2>/dev/null | \
            grep -oE "claude-[a-z]+-[0-9-]+" | sort -u | head -10); then
            while IFS= read -r model; do
                [[ -n "$model" ]] && models+=("$model")
            done <<< "$docs_models"
        fi
    fi

    # Fallback
    if [[ ${#models[@]} -eq 0 ]]; then
        models=("claude-sonnet-4-5-20250929" "claude-haiku-4-5-20251001")
    fi

    printf '%s\n' "${models[@]}"
}

# Fetch MiniMax models (NASA Rule 4: <60 lines)
fetch_minimax_models() {
    local openrouter_models="$1"
    local models=()

    # Extract from OpenRouter
    if [[ -n "$openrouter_models" ]]; then
        while IFS='|' read -r model_id context_length prompt_price completion_price; do
            if [[ "$model_id" == minimax/* ]] || [[ "$model_id" == *minimax* ]]; then
                local clean_model="${model_id#*/}"
                models+=("$clean_model")
            fi
        done <<< "$openrouter_models"
    fi

    # Fallback
    if [[ ${#models[@]} -eq 0 ]]; then
        models=("MiniMax-M2" "MiniMax-M1")
    fi

    printf '%s\n' "${models[@]}"
}

# Fetch Kimi/Moonshot models (NASA Rule 4: <60 lines)
fetch_kimi_models() {
    local openrouter_models="$1"
    local models=()
    local line_count=0

    # Extract from OpenRouter (NASA Rule 2: Fixed bound)
    if [[ -n "$openrouter_models" ]]; then
        while IFS='|' read -r model_id context_length prompt_price completion_price; do
            if [[ $line_count -ge $MAX_FETCH_LINES ]]; then
                break
            fi
            if [[ "$model_id" == *moonshot* ]] || [[ "$model_id" == *kimi* ]]; then
                local clean_model="${model_id#*/}"
                models+=("$clean_model")
            fi
            line_count=$((line_count + 1))
        done <<< "$openrouter_models"
    fi

    # Try Kimi API directly
    if [[ ${#models[@]} -eq 0 ]] && command -v curl >/dev/null 2>&1 && [[ -n "${KIMI_AUTH_TOKEN:-}" ]]; then
        local kimi_models
        if kimi_models=$(curl -s --max-time "$PROVIDER_API_TIMEOUT" \
            -H "Authorization: Bearer $KIMI_AUTH_TOKEN" \
            "$KIMI_BASE_URL/models" 2>/dev/null | \
            jq -r '.data[].id // empty' 2>/dev/null | grep -E "(moonshot|kimi)"); then

            local kimi_line_count=0
            while IFS= read -r model; do
                if [[ $kimi_line_count -ge $MAX_PROVIDER_PARSE_LINES ]]; then
                    break
                fi
                [[ -n "$model" ]] && models+=("$model")
                kimi_line_count=$((kimi_line_count + 1))
            done <<< "$kimi_models"
        fi
    fi

    # Fallback
    if [[ ${#models[@]} -eq 0 ]]; then
        models=("moonshot-v1-256k" "moonshot-v1-128k" "moonshot-v1-32k" "moonshot-v1-8k")
    fi

    printf '%s\n' "${models[@]}"
}

# Fetch GLM models (NASA Rule 4: <60 lines)
fetch_glm_models() {
    local openrouter_models="$1"
    local models=()
    local line_count=0

    # Extract from OpenRouter (NASA Rule 2: Fixed bound)
    if [[ -n "$openrouter_models" ]]; then
        while IFS='|' read -r model_id context_length prompt_price completion_price; do
            if [[ $line_count -ge $MAX_FETCH_LINES ]]; then
                break
            fi

            if [[ "$model_id" == *glm* ]] || [[ "$model_id" == zhipuai/* ]] || [[ "$model_id" == *chatglm* ]]; then
                local clean_model="${model_id#*/}"

                case "$clean_model" in
                    "glm-4.6"|"glm-4.6-exacto"|"glm-4.6-boost") models+=("glm-4.6") ;;
                    "glm-4.5v"|"glm-4.5"|"glm-4.5-latest") models+=("glm-4.5") ;;
                    "glm-4.5-air"|"glm-4.5-air:free"|"glm-4.5-air-int4") models+=("glm-4.5-air") ;;
                    "glm-4"|"glm-4-latest") models+=("glm-4") ;;
                    "glm-4-flash"|"glm-4-flashx") models+=("glm-4-flash") ;;
                    "glm-3-turbo"|"glm-3-turbo-latest") models+=("glm-3-turbo") ;;
                    "chatglm3"|"chatglm3-6b") models+=("chatglm3") ;;
                    *zhipuai*)
                        local model_name="${clean_model##*/}"
                        case "$model_name" in
                            *glm-4.6*) models+=("glm-4.6") ;;
                            *glm-4.5*) models+=("glm-4.5") ;;
                            *glm-4*) models+=("glm-4") ;;
                            *glm-3*) models+=("glm-3-turbo") ;;
                            *) models+=("$model_name") ;;
                        esac
                        ;;
                    *) models+=("$clean_model") ;;
                esac
            fi
            line_count=$((line_count + 1))
        done <<< "$openrouter_models"
    fi

    # Try Z.ai API directly
    if [[ ${#models[@]} -eq 0 ]] && command -v curl >/dev/null 2>&1 && [[ -n "${ZAI_AUTH_TOKEN:-}" ]]; then
        local zai_models
        if zai_models=$(curl -s --max-time "$PROVIDER_API_TIMEOUT" \
            -H "Authorization: Bearer $ZAI_AUTH_TOKEN" \
            "$ZAI_BASE_URL/v1/models" 2>/dev/null | \
            jq -r '.data[].id // empty' 2>/dev/null | grep glm); then

            local zai_line_count=0
            while IFS= read -r model; do
                if [[ $zai_line_count -ge $MAX_PROVIDER_PARSE_LINES ]]; then
                    break
                fi
                [[ -n "$model" ]] && models+=("$model")
                zai_line_count=$((zai_line_count + 1))
            done <<< "$zai_models"
        fi
    fi

    # Fallback
    if [[ ${#models[@]} -eq 0 ]]; then
        models=("glm-4.6" "glm-4.5" "glm-4.5-air" "glm-4" "glm-3-turbo" "chatglm3")
    fi

    printf '%s\n' "${models[@]}"
}

# ============================================================================
# MAIN FETCH FUNCTION
# ============================================================================

# Fetch available models from providers (NASA Rule 4: <60 lines)
fetch_available_models() {
    local provider="$1"
    local models=()

    log_info "Fetching available ${provider} models..."

    # Get OpenRouter data once (shared across providers)
    local openrouter_models
    openrouter_models=$(fetch_openrouter_data) || openrouter_models=""

    # Dispatch to provider-specific function
    # Bash 3.2 compatible - use while loop instead of readarray
    case "$provider" in
        "standard")
            models=()
            while IFS= read -r line; do
                models+=("$line")
            done < <(fetch_standard_models "$openrouter_models")
            ;;
        "minimax")
            models=()
            while IFS= read -r line; do
                models+=("$line")
            done < <(fetch_minimax_models "$openrouter_models")
            ;;
        "kimi"|"moonshot")
            models=()
            while IFS= read -r line; do
                models+=("$line")
            done < <(fetch_kimi_models "$openrouter_models")
            ;;
        "zai"|"glm")
            models=()
            while IFS= read -r line; do
                models+=("$line")
            done < <(fetch_glm_models "$openrouter_models")
            ;;
        *)
            log_error "Unknown provider: $provider"
            return 1
            ;;
    esac

    # Deduplicate results (pass array name as string)
    deduplicate_models "models"
}

# Get detailed model information from OpenRouter data
get_model_details() {
    local model_name="$1"
    local provider="$2"
    local details=""

    if command -v curl >/dev/null 2>&1; then
        local openrouter_data
        if openrouter_data=$(curl -s --max-time "$PROVIDER_API_TIMEOUT" \
            "https://openrouter.ai/api/v1/models" 2>/dev/null | \
            jq -r ".data[] | select(.id == \"$provider/$model_name\" or .id == \"$model_name\") | \"\(.context_length)|\(.pricing.prompt)|\(.pricing.completion)\"" 2>/dev/null); then

            IFS='|' read -r context_length prompt_price completion_price <<< "$openrouter_data"

            if [[ -n "$context_length" ]] && [[ "$context_length" != "null" ]]; then
                local formatted_context=$(format_context_length "$context_length")
                details=" $formatted_context"
            fi

            if [[ -n "$prompt_price" ]] && [[ "$prompt_price" != "null" ]]; then
                details+=" Price: $prompt_price/1M"
            fi
        fi
    fi

    echo "$details"
}
