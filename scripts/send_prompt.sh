#!/bin/bash
#
# send_prompt.sh
#
# This script sends a prompt to the local LLM using the `llama-cli` tool.
# It can receive prompt content in two ways: as a command-line argument and/or
# from standard input (pipe). It assembles these parts into a final prompt,
# sends it to the LLM, and then parses the raw output to extract only the
# generated text.
#
# Usage:
#   cat my_document.txt | ./send_prompt.sh --prompt "Summarize this document."
#
# Environment Variables:
#   - LLAMACPP_PATH: Path to the directory containing the llama-cli executable.
#   - MODEL_PATH: Full path to the GGUF model file.
#

set -euo pipefail
IFS=$'\n\t'

# Source utility functions and environment variables
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
setup_env

# --- Prompt Assembly ---

# Check for a prompt prefix passed as a command-line argument.
PROMPT_PREFIX=""
if [[ "${1:-}" == "--prompt" ]]; then
    PROMPT_PREFIX="$2"
    shift 2 # Remove --prompt and its value from the argument list
fi

# Read content from stdin if it's being piped.
# `tty -s` checks if stdin is a terminal. If it's not, data is being piped.
PIPED_CONTENT=""
if ! tty -s; then
  PIPED_CONTENT=$(cat)
fi

# Assemble the final prompt, separating the prefix and piped content with newlines
# to provide clear structure for the LLM.
PROMPT_CONTENT="${PROMPT_PREFIX}\n\n${PIPED_CONTENT}"

# Validate that the final assembled prompt is not empty.
if [[ -z "$(echo -e "${PROMPT_CONTENT}" | tr -d '[:space:]')" ]]; then
    log_error "Prompt content is empty. Provide it via the --prompt argument and/or stdin."
fi

# --- LLM Inference ---

# Call the llama-cli tool with the assembled prompt and specific parameters.
#   -m: Specifies the model file to use.
#   -p: Provides the prompt content.
#   -n: Sets the number of tokens to predict.
#   --single-turn: Indicates a single, non-interactive session.
#   --no-display-prompt: Prevents the tool from echoing the input prompt.
#   --no-warmup: Skips the warmup phase for faster execution.
#   2>&1: Redirects stderr to stdout to capture all output from the tool.
RAW_OUTPUT=$("$LLAMACPP_PATH"/llama-cli \
  -m "$MODEL_PATH" \
  -p "$PROMPT_CONTENT" \
  -n 256 \
  --single-turn \
  --no-display-prompt \
  --no-warmup 2>&1)

# --- Output Parsing ---

# The raw output from llama-cli includes logging and other text. This pipeline
# extracts only the generated response.
#
# 1. `sed -n '/generate:/,/\[end of text\]/p'`:
#    - This `sed` command prints the lines between the marker `generate:` (which
#      appears in llama-cli's log output before the response) and `[end of text]`.
#
# 2. `sed '1d;$d'`:
#    - This second `sed` command deletes the first line (the `generate:` marker itself)
#      and the last line (`[end of text]`) from the block, leaving only the clean response.
echo "$RAW_OUTPUT" | sed -n '/generate:/,/\[end of text\]/p' | sed '1d;$d'
