#!/bin/bash
# check_server_status.sh - Verifies that the llama.cpp server is running and reachable.

set -euo pipefail
IFS=$'\n\t'

# Source utility functions and environment
source "$(dirname "$0")/utils.sh"
setup_env

# --- Dependencies ---
check_deps "curl"

# --- Main Logic ---
main() {
    log_info "Checking server status at ${LLAMACPP_SERVER_URL}..."

    if curl -s --fail -o /dev/null "${LLAMACPP_SERVER_URL}"; then
        log_info "✅ Server is running and reachable."
    else
        log_error "❌ Server is NOT reachable at ${LLAMACPP_SERVER_URL}. Please ensure the llama.cpp server is running."
    fi
}

main