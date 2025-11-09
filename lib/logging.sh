#!/usr/bin/env bash

# Logging utilities
# Single Responsibility: Provide colorized logging functions

# Bash safety: exit on error, undefined vars, pipe failures
set -euo pipefail

# Info log (stderr)
# NASA Rule 7: Validate parameter
log_info() {
    local message="${1:-}"
    if [[ -z "$message" ]]; then
        echo -e "${BLUE}[INFO]${NC} (empty message)" >&2
        return 0
    fi
    echo -e "${BLUE}[INFO]${NC} $message" >&2
}

# Success log (stderr)
# NASA Rule 7: Validate parameter
log_success() {
    local message="${1:-}"
    if [[ -z "$message" ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} (empty message)" >&2
        return 0
    fi
    echo -e "${GREEN}[SUCCESS]${NC} $message" >&2
}

# Warning log (stderr)
# NASA Rule 7: Validate parameter
log_warning() {
    local message="${1:-}"
    if [[ -z "$message" ]]; then
        echo -e "${YELLOW}[WARNING]${NC} (empty message)" >&2
        return 0
    fi
    echo -e "${YELLOW}[WARNING]${NC} $message" >&2
}

# Error log (stderr)
# NASA Rule 7: Validate parameter
log_error() {
    local message="${1:-}"
    if [[ -z "$message" ]]; then
        echo -e "${RED}[ERROR]${NC} (empty message)" >&2
        return 0
    fi
    echo -e "${RED}[ERROR]${NC} $message" >&2
}
