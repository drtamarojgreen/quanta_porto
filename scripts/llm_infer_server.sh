#!/bin/bash
#
# llm_infer_server.sh
#
# This script sends a text prompt to a running llama.cpp server for inference.
# It can receive the prompt either as a command-line argument or via standard input (pipe).
# The script constructs a JSON payload, sends it to the server's API endpoint,
# parses the JSON response, and outputs the generated text content.
#
# Dependencies: curl, jq
# Environment Variables: LLAMACPP_SERVER_URL, LLAMACPP_SERVER_ENDPOINT
#

set -euo pipefail
IFS=$'\n\t'

# Source utility functions and environment
source "$(dirname "$0")/utils.sh"
setup_env

# --- Dependencies ---
# Ensure that curl (for making HTTP requests) and jq (for JSON processing) are installed.
check_deps "curl" "jq"

# --- Main Logic ---
main() {
    local prompt_text
    # Read prompt text from the first command-line argument.
    if [[ -n "${1:-}" ]]; then
        prompt_text="$1"
    # If no argument is provided, check if data is being piped via stdin.
    # '-t 0' checks if file descriptor 0 (stdin) is connected to a terminal.
    elif ! [[ -t 0 ]]; then
        prompt_text=$(cat)
    else
        # If there's no argument and no pipe, show usage and exit.
        log_error "Usage: $0 <prompt_text> or pipe prompt into script."
    fi

    log_info "Sending prompt to LLM server at $LLAMACPP_SERVER_URL..."

    # Construct the JSON payload for the llama.cpp server API.
    # - `jq -n`: Creates a JSON object from scratch.
    # - `--arg prompt "$prompt_text"`: Safely passes the prompt text as a variable to jq.
    # - '{...}': Defines the JSON structure with the prompt and inference parameters.
    local json_payload
    json_payload=$(jq -n \
        --arg prompt "$prompt_text" \
        '{prompt: $prompt, n_predict: 1024, temperature: 0.7}')

    # Send the request to the server using curl.
    # - `-s`: Silent mode, suppresses progress meter.
    # - `-X POST`: Specifies the HTTP POST method.
    # - `-H "Content-Type: application/json"`: Sets the content type header.
    # - `-d "$json_payload"`: Sends the JSON data as the request body.
    local response
    response=$(curl -s -X POST "${LLAMACPP_SERVER_URL}${LLAMACPP_SERVER_ENDPOINT}" \
        -H "Content-Type: application/json" \
        -d "$json_payload")

    if [[ -z "$response" ]]; then
        log_error "Received empty response from LLM server at ${LLAMACPP_SERVER_URL}."
    fi

    # Safely parse the 'content' field from the JSON response using jq.
    # - `jq -r '.content'`: Extracts the value of the 'content' key.
    #   The '-r' flag outputs the raw string without JSON quotes.
    local content
    content=$(echo "$response" | jq -r '.content')

    # Output the final generated text.
    echo "$content"
}

# Pass all command-line arguments to the main function.
main "$@"