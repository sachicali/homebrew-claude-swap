#!/usr/bin/env bash

# Model detection and mapping utilities
# Single Responsibility: Handle model family detection and provider mapping

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# Note: logging.sh is sourced by the main claudeswap script

# Detect model family from model identifier
# NASA Rule 7: Validate input parameter
detect_model_family() {
    local model_name="${1:-unknown}"

    if [[ -z "$model_name" ]]; then
        echo "unknown"
        return 0
    fi

    case "$model_name" in
        # Standard Anthropic models
        *"claude-sonnet"*) echo "sonnet" ;;
        *"claude-haiku"*) echo "haiku" ;;
        # Short names
        "sonnet"|"sonnet4"|"sonnet-4") echo "sonnet" ;;
        "haiku"|"haiku4"|"haiku-4") echo "haiku" ;;
        # MiniMax models
        *"MiniMax"*) echo "minimax" ;;
        # GLM models
        *"glm-"*) echo "glm" ;;
        # Kimi/Moonshot models
        *"kimi-k2"*) echo "kimi-k2" ;;
        *"kimi"*|*"moonshot"*) echo "kimi" ;;
        # Special cases
        "<synthetic>") echo "synthetic" ;;
        # Default fallback
        *) echo "unknown" ;;
    esac
}

# Detect model tier (performance level)
detect_model_tier() {
    local model_name="$1"
    local model_family=$(detect_model_family "$model_name")

    case "$model_family" in
        "sonnet"|"opus") echo "high" ;;
        "haiku") echo "medium" ;;
        "glm") echo "medium" ;;
        "minimax") echo "high" ;;
        "kimi") echo "high" ;;
        "kimi-k2") echo "very-high" ;;  # K2 beats GPT-4.1 on coding
        *) echo "medium" ;;
    esac
}

# Map model to target provider's equivalent
map_model_to_provider() {
    local model_name="$1"
    local target_provider="$2"

    # Detect model family and characteristics
    local model_family=$(detect_model_family "$model_name")

    # Map to target provider's equivalent model
    case "$target_provider" in
        "standard")
            # Anthropic API - use exact model names
            case "$model_family" in
                "sonnet") echo "claude-sonnet-4-5-20250929" ;;
                "haiku") echo "claude-haiku-4-5-20251001" ;;
                "glm") echo "claude-sonnet-4-5-20250929" ;;
                "minimax") echo "claude-sonnet-4-5-20250929" ;;
                *) echo "claude-sonnet-4-5-20250929" ;;
            esac
            ;;
        "minimax")
            # MiniMax API models
            case "$model_family" in
                "sonnet"|"haiku"|"opus") echo "MiniMax-M2" ;;
                "glm") echo "MiniMax-M2" ;;
                "minimax") echo "$model_name" ;;
                *) echo "MiniMax-M2" ;;
            esac
            ;;
        "zai"|"glm")
            # Z.ai GLM API
            case "$model_family" in
                "sonnet") echo "glm-4.6" ;;
                "haiku") echo "glm-4.5-air" ;;
                "glm") echo "$model_name" ;;
                "minimax") echo "glm-4.6" ;;
                "kimi") echo "glm-4.6" ;;
                *) echo "glm-4.6" ;;
            esac
            ;;
        "kimi"|"moonshot")
            # Kimi/Moonshot API - using latest K2 Turbo (4x faster, Aug 2025)
            case "$model_family" in
                "sonnet"|"opus") echo "kimi-k2-turbo-preview" ;;
                "haiku") echo "kimi-k2-turbo-preview" ;;
                "glm") echo "kimi-k2-turbo-preview" ;;
                "minimax") echo "kimi-k2-turbo-preview" ;;
                "kimi") echo "$model_name" ;;
                *) echo "kimi-k2-turbo-preview" ;;  # Default to K2 Turbo (40 tok/s)
            esac
            ;;
        "kimi-for-coding")
            # Official Moonshot Kimi for Coding Plan (Membership-based)
            # Dedicated endpoint: https://api.kimi.com/coding/
            # Model name is always "kimi-for-coding" regardless of family
            echo "kimi-for-coding" ;;
            ;;
        *)
            # Unknown provider - use safe defaults
            echo "claude-sonnet-4-5-20250929"
            ;;
    esac
}
