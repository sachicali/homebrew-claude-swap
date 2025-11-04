#!/usr/bin/env bash

# Logging utilities
# Single Responsibility: Provide colorized logging functions

# Info log (stderr)
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

# Success log (stderr)
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

# Warning log (stderr)
log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

# Error log (stderr)
log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}
