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

# Fetch available models from providers dynamically
fetch_available_models() {
    local provider="$1"
    local models=()

    # Get OpenRouter model list as reference (public, no auth needed)
    local openrouter_models=""
    if command -v curl >/dev/null 2>&1; then
        openrouter_models=$(curl -s --max-time 15 \
            "https://openrouter.ai/api/v1/models" 2>/dev/null | \
            jq -r '.data[] | "\(.id)|\(.context_length)|\(.pricing.prompt)|\(.pricing.completion)"' 2>/dev/null || echo "")
    fi

    case "$provider" in
        "standard")
            log_info "Fetching available Anthropic models..."

            # Extract Anthropic models from OpenRouter data
            if [[ -n "$openrouter_models" ]]; then
                while IFS='|' read -r model_id context_length prompt_price completion_price; do
                    if [[ "$model_id" == anthropic/* ]]; then
                        local clean_model="${model_id#anthropic/}"
                        # Convert OpenRouter naming to Anthropic API naming
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

            # Try direct Anthropic docs as backup
            if [[ -z "${models:-}" ]] || [[ ${#models[@]} -eq 0 ]] && command -v curl >/dev/null 2>&1; then
                local docs_models=$(curl -s --max-time 10 \
                    "https://docs.anthropic.com/en/api/models" 2>/dev/null | \
                    grep -oE "claude-[a-z]+-[0-9-]+" | sort -u | head -10)

                while IFS= read -r model; do
                    [[ -n "$model" ]] && models+=("$model")
                done <<< "$docs_models"
            fi

            # Final fallback to known current models
            if [[ -z "${models:-}" ]] || [[ ${#models[@]} -eq 0 ]]; then
                models=("claude-sonnet-4-5-20250929" "claude-haiku-4-5-20251001")
            fi
            ;;
        "minimax")
            log_info "Fetching available MiniMax models..."

            # Extract MiniMax models from OpenRouter data
            if [[ -n "$openrouter_models" ]]; then
                while IFS='|' read -r model_id context_length prompt_price completion_price; do
                    if [[ "$model_id" == minimax/* ]] || [[ "$model_id" == *minimax* ]]; then
                        local clean_model="${model_id#*/}"
                        models+=("$clean_model")
                    fi
                done <<< "$openrouter_models"
            fi

            # Fallback to known MiniMax models
            if [[ -z "${models:-}" ]] || [[ ${#models[@]} -eq 0 ]]; then
                models=("MiniMax-M2" "MiniMax-M1")
            fi
            ;;
        "kimi"|"moonshot")
            log_info "Fetching available Kimi/Moonshot models..."

            # Extract Moonshot models from OpenRouter data
            if [[ -n "$openrouter_models" ]]; then
                local max_lines=500  # NASA Rule 2: Fixed loop bound
                local line_count=0
                while IFS='|' read -r model_id context_length prompt_price completion_price; do
                    if [[ $line_count -ge $max_lines ]]; then
                        break
                    fi
                    if [[ "$model_id" == *moonshot* ]] || [[ "$model_id" == *kimi* ]]; then
                        local clean_model="${model_id#*/}"
                        models+=("$clean_model")
                    fi
                    line_count=$((line_count + 1))
                done <<< "$openrouter_models"
            fi

            # Try Moonshot API directly if we have auth
            if [[ -z "${models:-}" ]] || [[ ${#models[@]} -eq 0 ]] && command -v curl >/dev/null 2>&1 && [[ -n "$KIMI_AUTH_TOKEN" ]]; then
                local kimi_models=$(curl -s --max-time 10 \
                    -H "Authorization: Bearer $KIMI_AUTH_TOKEN" \
                    "$KIMI_BASE_URL/models" 2>/dev/null | \
                    jq -r '.data[].id // empty' 2>/dev/null | grep -E "(moonshot|kimi)" || echo "")

                local max_kimi_lines=100  # NASA Rule 2: Fixed loop bound
                local kimi_line_count=0
                while IFS= read -r model; do
                    if [[ $kimi_line_count -ge $max_kimi_lines ]]; then
                        break
                    fi
                    [[ -n "$model" ]] && models+=("$model")
                    kimi_line_count=$((kimi_line_count + 1))
                done <<< "$kimi_models"
            fi

            # Fallback to known Kimi/Moonshot models
            if [[ -z "${models:-}" ]] || [[ ${#models[@]} -eq 0 ]]; then
                models=(
                    "moonshot-v1-256k"
                    "moonshot-v1-128k"
                    "moonshot-v1-32k"
                    "moonshot-v1-8k"
                )
            fi
            ;;
        "zai"|"glm")
            log_info "Fetching available GLM models..."

            # Enhanced GLM model detection from OpenRouter data
            if [[ -n "$openrouter_models" ]]; then
                local max_lines=500  # NASA Rule 2: Fixed loop bound
                local line_count=0
                while IFS='|' read -r model_id context_length prompt_price completion_price; do
                    if [[ $line_count -ge $max_lines ]]; then
                        break
                    fi
                    # More comprehensive GLM model detection
                    if [[ "$model_id" == *glm* ]] || [[ "$model_id" == zhipuai/* ]] || [[ "$model_id" == *chatglm* ]]; then
                        local clean_model="${model_id#*/}"

                        # Enhanced model mapping with better GLM detection
                        case "$clean_model" in
                            # Latest GLM models
                            "glm-4.6"|"glm-4.6-exacto"|"glm-4.6-boost") models+=("glm-4.6") ;;
                            "glm-4.5v"|"glm-4.5"|"glm-4.5-latest") models+=("glm-4.5") ;;
                            "glm-4.5-air"|"glm-4.5-air:free"|"glm-4.5-air-int4") models+=("glm-4.5-air") ;;
                            "glm-4"|"glm-4-latest") models+=("glm-4") ;;
                            "glm-4-flash"|"glm-4-flashx") models+=("glm-4-flash") ;;
                            # Older GLM models
                            "glm-3-turbo"|"glm-3-turbo-latest") models+=("glm-3-turbo") ;;
                            "chatglm3"|"chatglm3-6b") models+=("chatglm3") ;;
                            "glm-130b"|"glm-6b") models+=("$clean_model") ;;
                            # ZhipuAI specific naming
                            *zhipuai*)
                                # Extract just the model name from zhipuai paths
                                local model_name="${clean_model##*/}"
                                case "$model_name" in
                                    *glm-4.6*) models+=("glm-4.6") ;;
                                    *glm-4.5*) models+=("glm-4.5") ;;
                                    *glm-4*) models+=("glm-4") ;;
                                    *glm-3*) models+=("glm-3-turbo") ;;
                                    *) models+=("$model_name") ;;
                                esac
                                ;;
                            # Default fallback
                            *) models+=("$clean_model") ;;
                        esac
                    fi
                    line_count=$((line_count + 1))
                done <<< "$openrouter_models"
            fi

            # Try Z.ai API directly if we have auth
            if [[ -z "${models:-}" ]] || [[ ${#models[@]} -eq 0 ]] && command -v curl >/dev/null 2>&1 && [[ -n "$ZAI_AUTH_TOKEN" ]]; then
                local zai_models=$(curl -s --max-time 10 \
                    -H "Authorization: Bearer $ZAI_AUTH_TOKEN" \
                    "$ZAI_BASE_URL/v1/models" 2>/dev/null | \
                    jq -r '.data[].id // empty' 2>/dev/null | grep glm || echo "")

                local max_zai_lines=100  # NASA Rule 2: Fixed loop bound
                local zai_line_count=0
                while IFS= read -r model; do
                    if [[ $zai_line_count -ge $max_zai_lines ]]; then
                        break
                    fi
                    [[ -n "$model" ]] && models+=("$model")
                    zai_line_count=$((zai_line_count + 1))
                done <<< "$zai_models"
            fi

            # Enhanced final fallback to best known GLM models (prioritized)
            if [[ -z "${models:-}" ]] || [[ ${#models[@]} -eq 0 ]]; then
                models=(
                    "glm-4.6"
                    "glm-4.5"
                    "glm-4.5-air"
                    "glm-4"
                    "glm-3-turbo"
                    "chatglm3"
                )
            fi
            ;;
    esac

    # Remove duplicates and sort (compatible with bash and zsh)
    # NASA Rule 2: Fixed bounds on all loops
    local unique_models=()
    local max_unique=200  # Fixed upper bound
    local unique_count=0

    # Safe array iteration that works in both bash and zsh
    if [[ ${#models[@]} -gt 0 ]]; then
        local max_models=500  # Fixed upper bound
        local model_idx=0
        for model in "${models[@]}"; do
            if [[ $model_idx -ge $max_models ]] || [[ $unique_count -ge $max_unique ]]; then
                break
            fi
            local found=0
            local existing_idx=0
            local max_existing=200  # Fixed upper bound for inner loop
            for existing in "${unique_models[@]}"; do
                if [[ $existing_idx -ge $max_existing ]]; then
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
        done
    fi

    printf '%s\n' "${unique_models[@]}"
}

# Get detailed model information from OpenRouter data
get_model_details() {
    local model_name="$1"
    local provider="$2"
    local details=""

    if command -v curl >/dev/null 2>&1; then
        local openrouter_data=$(curl -s --max-time 10 \
            "https://openrouter.ai/api/v1/models" 2>/dev/null | \
            jq -r ".data[] | select(.id == \"$provider/$model_name\" or .id == \"$model_name\") | \"\(.context_length)|\(.pricing.prompt)|\(.pricing.completion)\"" 2>/dev/null)

        if [[ -n "$openrouter_data" ]]; then
            IFS='|' read -r context_length prompt_price completion_price <<< "$openrouter_data"

            # Format context length
            if [[ -n "$context_length" ]] && [[ "$context_length" != "null" ]]; then
                local formatted_context=$(format_context_length "$context_length")
                details=" $formatted_context"
            fi

            # Add price info
            if [[ -n "$prompt_price" ]] && [[ "$prompt_price" != "null" ]]; then
                details+=" Price: $prompt_price/1M"
            fi
        fi
    fi

    echo "$details"
}
