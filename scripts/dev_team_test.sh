#!/bin/bash
#
# dev_team_test.sh
#
# This script sends a multi-role chat prompt to a running llama.cpp server
# to test its ability to simulate a collaborative developer team. It uses the
# chat completions endpoint, which is standard for conversational models.
#
# The script defines a system message to set the AI's persona and a user
# message to kick off the task. It then parses the JSON response to extract
# and display the assistant's reply.
#
# Dependencies: curl, jq
#

set -euo pipefail
IFS=$'\n\t'

# The URL for the chat completions endpoint of the llama.cpp server.
LLAMA_SERVER="http://localhost:8080/v1/chat/completions"

# Define the JSON payload for the chat completions request using a HEREDOC.
# This structure allows for defining multiple roles (system, user, assistant)
# to create a conversational context for the model.
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

# Use curl to send the POST request with the JSON payload.
RESPONSE=$(curl -s -X POST "$LLAMA_SERVER" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

# Use jq to parse the JSON response from the server.
# The path `.choices[0].message.content` is specific to the OpenAI-compatible
# chat completions API format. It extracts the text content of the first
# choice in the response.
ASSISTANT_REPLY=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

# Pretty-print the assistant's reply for easy reading.
echo -e "\n===== Developer Team Response =====\n"
echo "$ASSISTANT_REPLY"
echo -e "\n==================================\n"
