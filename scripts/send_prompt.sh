#!/bin/bash
# send_prompt.sh - Sends a prompt to the LLM.
# This script relies on environment variables (LLAMACPP_PATH, MODEL_PATH)
# being set and exported by the calling script.

# Source utility functions
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$script_dir/utils.sh"

# Setup environment
setup_env

PROMPT_PREFIX=""
if [[ "${1:-}" == "--prompt" ]]; then
    PROMPT_PREFIX="$2"
    shift 2
fi

# Read piped content from stdin
PIPED_CONTENT=""
if ! tty -s; then
  PIPED_CONTENT=$(cat)
fi

# Assemble the final prompt. Add newlines for separation.
PROMPT_CONTENT="${PROMPT_PREFIX}\n\n${PIPED_CONTENT}"

# Check if the final prompt is empty (ignoring whitespace and newlines)
if [[ -z "$(echo -e "${PROMPT_CONTENT}" | tr -d '[:space:]')" ]]; then
    log_error "Prompt content is empty. Provide it via --prompt argument and/or stdin."
fi

# Call the LLM with the provided prompt content
RAW_OUTPUT=$("$LLAMACPP_PATH"/llama-cli \
  -m "$MODEL_PATH" \
  -p "$PROMPT_CONTENT" \
  -n 256 \
  --single-turn \
  --no-display-prompt \
  --no-warmup 2>&1)

# Parse the output to extract the generated text
echo "$RAW_OUTPUT" | sed -n '/generate:/,/\[end of text\]/p' | sed '1d;$d'
