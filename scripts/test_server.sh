#!/bin/bash
#
# test_server.sh
#
# This script performs a basic health check and a test query against a running
# llama.cpp server. It first checks if the server is reachable at the specified
# URL and then sends a predefined test prompt to the completion endpoint.
# It then parses and prints the 'content' field from the JSON response.
#
# This is useful for quickly verifying that the LLM server is up and responding correctly.
#

set -euo pipefail
IFS=$'\n\t'

# The base URL for the llama.cpp server.
LLAMA_SERVER="http://localhost:8080"
# The specific endpoint for completion requests.
TEST_ENDPOINT="$LLAMA_SERVER/completion"

# Checks if the llama.cpp server is running and reachable.
check_server() {
    echo "Checking if llamacpp server is running at $LLAMA_SERVER..."

    # `curl --silent --fail` attempts to fetch the URL.
    # `--silent` hides the progress meter.
    # `--fail` makes curl return a non-zero exit code on server errors (like 404 or 500).
    # Output is redirected to /dev/null as we only care about the exit code.
    if ! curl --silent --fail "$LLAMA_SERVER" > /dev/null; then
        echo "❌ llamacpp server is not reachable on $LLAMA_SERVER"
        exit 1
    else
        echo "✅ llamacpp server is running."
    fi
}

# Sends a predefined test prompt to the server's completion endpoint.
send_test_prompt() {
    echo "Sending test prompt..."

    # A HEREDOC is used to define the multi-line JSON payload.
    read -r -d '' JSON_PAYLOAD << EOM
{
  "prompt": "What is the capital of France?",
  "system": "You are a helpful assistant.",
  "n_predict": 64,
  "temperature": 0.7,
  "top_k": 40,
  "top_p": 0.9,
  "repeat_penalty": 1.1
}
EOM

    # Use curl to send the POST request with the JSON payload.
    local RESPONSE
    RESPONSE=$(curl -s -X POST "$TEST_ENDPOINT" \
        -H "Content-Type: application/json" \
        -d "$JSON_PAYLOAD")

    echo "Response:"
    # This pipeline parses the 'content' from the JSON response.
    # 1. `sed -n 's/.../p'`: Extracts the content value, which may contain escaped characters.
    # 2. `sed 's/\\"/g; s/\\n/\n/g'`: Un-escapes quotes and newlines for clean display.
    echo "$RESPONSE" | sed -n 's/.*"content"[[:space:]]*:[[:space:]]*"\(.*\)",.*/\1/p' | sed 's/\\"/"/g; s/\\n/\n/g'
}

# --- Main Execution ---
check_server
send_test_prompt
