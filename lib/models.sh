#!/usr/bin/env bash

# Model detection and mapping utilities
# Single Responsibility: Handle model family detection and provider mapping

# Note: logging.sh is sourced by the main claudeswap script

# Detect model family from model identifier
detect_model_family() {
    local model_name="$1"

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
                *) echo "glm-4.6" ;;
            esac
            ;;
        *)
            # Unknown provider - use safe defaults
            echo "claude-sonnet-4-5-20250929"
            ;;
    esac
}
