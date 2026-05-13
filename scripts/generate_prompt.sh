#!/bin/bash
#
# generate_prompt.sh
#
# This script assembles a structured LLM prompt based on a task defined in a PQL file.
# It takes a task ID as input, uses 'parse_pql.sh' to extract the task's description,
# commands, and criteria, and then combines them with document content piped via stdin.
# The final output is a formatted prompt ready to be sent to an LLM.
#
# Usage: cat <document> | ./generate_prompt.sh <task_id>
#

set -euo pipefail
IFS=$'\n\t'

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Setup environment variables like PQL_FILE
setup_env

# --- Helper Functions ---

usage() {
  echo "Usage: $0 <task_id>"
  echo "  Generates a structured prompt for the given task ID."
  echo "  Expects document content to be piped via stdin."
  exit 1
}

# --- Main Execution ---
main() {

  local task_id="${1-}"
  if [[ -z "$task_id" ]]; then
    log_error "Task ID is required."
    usage
  fi

  # Ensure the PQL file defined in the environment exists.
  if [[ ! -f "$PQL_FILE" ]]; then
    log_error "PQL file not found at '$PQL_FILE'"
  fi

  # Verify that the task ID exists in the PQL file before proceeding.
  if ! "$PRISM_QUANTA_ROOT/scripts/parse_pql.sh" exists "$task_id"; then
    log_error "Task ID '$task_id' not found in $PQL_FILE."
    exit 1
  fi

  # Read document content from stdin.
  # 'tty -s' checks if stdin is a terminal. If it's not, data is being piped.
  local doc_content
  if ! tty -s; then
    doc_content=$(cat)
  else
    doc_content="" # Handle the case where nothing is piped.
  fi

  # --- Extract Data from PQL ---
  # Use the parse_pql.sh script to retrieve specific parts of the task definition.

  local task_description
  task_description=$("$PRISM_QUANTA_ROOT/scripts/parse_pql.sh" description "$task_id")

  # Get the commands and format them as a numbered list.
  # `awk '{print NR". "$0}'` prepends the line number (e.g., "1. ") to each command.
  local commands
  commands=$("$PRISM_QUANTA_ROOT/scripts/parse_pql.sh" commands "$task_id" | awk '{print NR". "$0}')

  # Get the criteria and format them as a bulleted list.
  # `sed 's/^/- /'` prepends a hyphen and space to each line.
  local criteria
  criteria=$("$PRISM_QUANTA_ROOT/scripts/parse_pql.sh" criteria "$task_id" | sed 's/^/- /')

  # --- Assemble the Prompt ---
  # Use a HEREDOC to construct the final prompt with clear sections.
  # This structure helps the LLM understand the context and instructions.
  cat << PROMPT
[SYSTEM]
You are a highly capable AI assistant. Your task is to follow a set of commands and adhere to specific criteria to produce a precise output. Do not deviate from the instructions.

[TASK]
$task_description

[COMMANDS]
$commands

[CRITERIA]
$criteria

[DOCUMENT CONTENT]
$doc_content

[RESPONSE]
PROMPT
}

# Run main
main "$@"