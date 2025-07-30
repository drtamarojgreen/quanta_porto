#!/bin/bash
# generate_prompt.sh - Assembles a structured LLM prompt from a PQL task.

set -euo pipefail
IFS=$'\n\t'

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Setup environment
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
  check_deps "xmlstarlet"

  local task_id="$1"
  if [[ -z "$task_id" ]]; then
    log_error "Task ID is required."
    usage
  fi

  if [[ ! -f "$PQL_FILE" ]]; then
    log_error "PQL file not found at '$PQL_FILE'"
  fi

  # Check if a task with the given ID exists
  local task_exists
  task_exists=$(xmlstarlet sel -t -v "count(/tasks/task[@id='$task_id'])" "$PQL_FILE")
  if [[ "$task_exists" -eq 0 ]]; then
    log_error "Task ID '$task_id' not found in $PQL_FILE."
  fi

  # Read document content from stdin
  local doc_content
  if ! tty -s; then
    doc_content=$(cat)
  else
    doc_content="" # Handle case where nothing is piped
  fi

  # Extract data from PQL using parse_pql.sh
  local task_description
  task_description=$("$PRISM_QUANTA_ROOT/scripts/parse_pql.sh" list | grep "^$task_id:" | cut -d' ' -f2-)

  local commands
  commands=$("$PRISM_QUANTA_ROOT/scripts/parse_pql.sh" commands "$task_id" | awk '{print NR". "$0}')

  local criteria
  criteria=$("$PRISM_QUANTA_ROOT/scripts/parse_pql.sh" criteria "$task_id" | sed 's/^/- /')

  # Assemble the prompt using a HEREDOC for clarity
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