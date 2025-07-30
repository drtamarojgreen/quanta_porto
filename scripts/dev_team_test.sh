#!/bin/bash

# URL of the running llama.cpp server
LLAMA_SERVER="http://localhost:8080/v1/chat/completions"

# JSON payload with your multi-role prompt
read -r -d '' PAYLOAD << EOF
{
  "model": "mistral",
  "messages": [
    {
      "role": "system",
      "content": "You are a collaborative developer team assistant."
    },
    {
      "role": "user",
      "content": "Build a simple task manager application."
    }
  ]
}
EOF

echo "Sending multi-role dev team prompt to llama.cpp server..."

RESPONSE=$(curl -s -X POST "$LLAMA_SERVER" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

# Extract and pretty-print the assistant's reply (basic jq usage)
# Adjust depending on your server's JSON response structure
ASSISTANT_REPLY=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

echo -e "\n===== Developer Team Response =====\n"
echo "$ASSISTANT_REPLY"
echo -e "\n==================================\n"
