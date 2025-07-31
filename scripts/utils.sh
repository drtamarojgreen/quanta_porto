#!/bin/bash
# utils.sh - Common utility functions for QuantaPorto scripts

# --- Environment Setup ---

# Sets up the environment for all scripts.
# It determines the project root, generates the environment script, and sources it.
setup_env() {
    # If the environment has already been sourced in this shell, do nothing.
    if [[ -n "${PRISM_QUANTA_ENV_SOURCED:-}" ]]; then
        return
    fi
 
    # Determine project root if it's not already set.
    if [[ -z "${PRISM_QUANTA_ROOT:-}" ]]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
        PRISM_QUANTA_ROOT="$(cd "$script_dir/.." &>/dev/null && pwd)"
        export PRISM_QUANTA_ROOT
    fi
 
    # Define a standard environment script path
    local env_script="/tmp/quantaporto_env.sh"
 
    # Generate the environment file
    "$PRISM_QUANTA_ROOT/scripts/generate_env.sh" "$PRISM_QUANTA_ROOT/environment.txt" "$env_script" "$PRISM_QUANTA_ROOT"
 
    # Source the environment file
    # shellcheck source=/dev/null
    source "$env_script"
    export PRISM_QUANTA_ENV_SOURCED=true
}


# --- Logging ---

# Logs an informational message.
# Usage: log_info "Your message here"
log_info() {
    # Only log if LOG_LEVEL is DEBUG or INFO
    if [[ "${LOG_LEVEL:-INFO}" == "DEBUG" || "${LOG_LEVEL:-INFO}" == "INFO" ]]; then
        echo "[INFO] $1"
    fi
}

# Logs a warning message.
# Usage: log_warn "Your message here"
log_warn() {
    # Only log if LOG_LEVEL is DEBUG, INFO, or WARN
    if [[ "${LOG_LEVEL:-INFO}" != "ERROR" ]]; then
        echo "[WARN] $1" >&2
    fi
}

# Logs an error message and exits.
# Usage: log_error "Your message here"
log_error() {
    # Errors are always logged regardless of level
    echo "[ERROR] $1" >&2
    exit 1
}


# --- Dependency Checking ---

# Appends a formatted message to the main application log file.
# Usage: append_to_log "Component: Your message"
append_to_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Checks for required command-line tools.
# Usage: check_deps "tool1" "tool2"
check_deps() {
    for dep in "$@"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Required command '$dep' is not installed. Please install it to continue."
        fi
    done
}
