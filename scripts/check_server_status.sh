#!/bin/bash
#
# check_server_status.sh
#
# This script performs a simple health check to verify that the llama.cpp server
# is running and reachable at the URL specified by the LLAMACPP_SERVER_URL
# environment variable.
#
# It uses curl to make a request to the server's root URL and checks the exit
# code to determine if the server is responsive.
#
# Dependencies: curl
#

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

    # Use curl to check the server status.
    # - `-s`: Silent mode, hides the progress meter.
    # - `--fail`: Returns a non-zero exit code on server errors (e.g., 404, 500),
    #             which is crucial for the if condition.
    # - `-o /dev/null`: Discards the actual response body, as we only need the
    #                   exit code to confirm connectivity.
    if curl -s --fail -o /dev/null "${LLAMACPP_SERVER_URL}"; then
        log_info "✅ Server is running and reachable."
    else
        log_error "❌ Server is NOT reachable at ${LLAMACPP_SERVER_URL}. Please ensure the llama.cpp server is running."
    fi
}

main