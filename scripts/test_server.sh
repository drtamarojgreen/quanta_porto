#!/bin/bash

# llamacpp default server URL
LLAMA_SERVER="http://localhost:8080"
TEST_ENDPOINT="$LLAMA_SERVER/completion"

# Function to check if llamacpp server is running
function check_server {
    echo "Checking if llamacpp server is running at $LLAMA_SERVER..."

    curl --silent --fail "$LLAMA_SERVER" > /dev/null
    if [ $? -ne 0 ]; then
        echo "❌ llamacpp server is not reachable on $LLAMA_SERVER"
        exit 1
    else
        echo "✅ llamacpp server is running."
    fi
}

# Function to send a test prompt
function send_test_prompt {
    echo "Sending test prompt..."

    # JSON payload for completion endpoint
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

    RESPONSE=$(curl -s -X POST "$TEST_ENDPOINT" \
        -H "Content-Type: application/json" \
        -d "$JSON_PAYLOAD")

    echo "Response:"
    echo "$RESPONSE"
}

# Main
check_server
send_test_prompt
