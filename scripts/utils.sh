#!/bin/bash
#
# utils.sh
#
# This script provides a set of common utility functions for the QuantaPorto project.
# It includes robust environment setup, standardized logging, and dependency checking.
# It is intended to be sourced by other scripts in the project.
#

# --- Environment Setup ---

# Sets up the environment for all scripts.
#
# This function ensures that all necessary environment variables are loaded. It determines
# the project's root directory, generates a temporary environment script from 'environment.txt',
# and then sources it. This makes variables like queue paths and log settings available
# to any script that calls this function.
#
# To avoid redundant operations, it checks if the environment has already been sourced
# using the PRISM_QUANTA_ENV_SOURCED flag.
setup_env() {
    # If the environment has already been sourced in this shell, do nothing.
    if [[ -n "${PRISM_QUANTA_ENV_SOURCED:-}" ]]; then
        return
    fi
 
    # Determine project root if it's not already set. This allows scripts to be
    # called from any directory.
    if [[ -z "${PRISM_QUANTA_ROOT:-}" ]]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
        PRISM_QUANTA_ROOT="$(cd "$script_dir/.." &>/dev/null && pwd)"
        export PRISM_QUANTA_ROOT
    fi
 
    # Define a standard environment script path in a temporary location.
    local env_script="/tmp/quantaporto_env.sh"
 
    # Generate the environment file by executing a dedicated script.
    "$PRISM_QUANTA_ROOT/scripts/generate_env.sh" "$PRISM_QUANTA_ROOT/environment.txt" "$env_script" "$PRISM_QUANTA_ROOT"
 
    # Source the environment file to load the variables.
    # The 'shellcheck' directive disables a warning about sourcing a non-constant path.
    # shellcheck source=/dev/null
    source "$env_script"
    export PRISM_QUANTA_ENV_SOURCED=true
}


# --- Logging ---

# Logs an informational message to standard output.
#
# This function prints messages with an [INFO] prefix. It respects the LOG_LEVEL
# environment variable and will only print if the level is 'INFO' or 'DEBUG'.
#
# Usage: log_info "Your message here"
#   $1: The message string to log.
log_info() {
    # Only log if LOG_LEVEL is DEBUG or INFO
    if [[ "${LOG_LEVEL:-INFO}" == "DEBUG" || "${LOG_LEVEL:-INFO}" == "INFO" ]]; then
        echo "[INFO] $1"
    fi
}

# Logs a warning message to standard error.
#
# This function prints messages with a [WARN] prefix. It respects the LOG_LEVEL
# environment variable and will print unless the level is set to 'ERROR'.
#
# Usage: log_warn "Your message here"
#   $1: The message string to log.
log_warn() {
    # Only log if LOG_LEVEL is DEBUG, INFO, or WARN
    if [[ "${LOG_LEVEL:-INFO}" != "ERROR" ]]; then
        echo "[WARN] $1" >&2
    fi
}

# Logs an error message to standard error and exits the script with a non-zero status.
#
# This function prints messages with an [ERROR] prefix. These messages are always
# printed, regardless of the LOG_LEVEL setting. The script will terminate immediately
# after the message is logged.
#
# Usage: log_error "Your message here"
#   $1: The message string to log.
log_error() {
    # Errors are always logged regardless of level
    echo "[ERROR] $1" >&2
    exit 1
}


# --- File and Dependency Management ---

# Appends a formatted message to the main application log file.
#
# This function adds a timestamped entry to the log file specified by the
# $LOG_FILE environment variable.
#
# Usage: append_to_log "Component: Your message"
#   $1: The message string to append.
append_to_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Checks for the existence of required command-line tools.
#
# This function iterates through a list of command names and terminates the script
# with an error if any of them are not found in the system's PATH.
#
# Usage: check_deps "tool1" "tool2"
#   $@: A list of command names to check for.
check_deps() {
    for dep in "$@"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Required command '$dep' is not installed. Please install it to continue."
        fi
    done
}
