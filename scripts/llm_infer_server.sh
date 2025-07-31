#!/bin/bash
# llm_infer_server.sh - Sends a prompt to a running llama.cpp server and returns the content.

set -euo pipefail
IFS=$'\n\t'

# Source utility functions and environment
source "$(dirname "$0")/utils.sh"
setup_env

# --- Dependencies ---
check_deps "curl" "jq"

# --- Main Logic ---
main() {
    local prompt_text
    # Read prompt from the first argument or from stdin if piped
    if [[ -n "${1:-}" ]]; then
        prompt_text="$1"
    elif ! [[ -t 0 ]]; then
        prompt_text=$(cat)
    else
        log_error "Usage: $0 <prompt_text> or pipe prompt into script."
    fi

    log_info "Sending prompt to LLM server at $LLAMACPP_SERVER_URL..."

    # Construct the JSON payload using jq to ensure it's well-formed.
    local json_payload
    json_payload=$(jq -n \
        --arg prompt "$prompt_text" \
        '{prompt: $prompt, n_predict: 1024, temperature: 0.7}')

    # Send the request to the server using curl.
    local response
    response=$(curl -s -X POST "${LLAMACPP_SERVER_URL}${LLAMACPP_SERVER_ENDPOINT}" \
        -H "Content-Type: application/json" \
        -d "$json_payload")

    if [[ -z "$response" ]]; then
        log_error "Received empty response from LLM server at ${LLAMACPP_SERVER_URL}."
    fi

    # Safely parse the 'content' field from the JSON response using jq.
    local content
    content=$(echo "$response" | jq -r '.content')

    # Output the final content.
    echo "$content"
}

main "$@"