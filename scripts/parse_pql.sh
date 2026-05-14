#!/bin/bash
#
# parse_pql.sh
#
# This script is a command-line utility for parsing and validating the PQL (QuantaPorto Language)
# task file (tasks.xml). It uses 'xmlstarlet' to perform XML queries and validation.
# The script can list tasks, extract specific details like commands or criteria for a given
# task ID, and validate the XML file against its XSD schema.
#
# This script can be executed directly or sourced by other scripts to use its functions.
#
# Dependencies: xmlstarlet
#

set -euo pipefail
IFS=$'\n\t'

# Source utility functions and environment variables
source "$(dirname "$0")/utils.sh"
setup_env

# For compatibility with the script's original variable names, map env vars.
PQL_FILE="$TASKS_XML_FILE"
PQL_SCHEMA="$PQL_SCHEMA_FILE"

# --- Core Logic ---

# Lists all task IDs and their descriptions from the PQL file.
#
# Uses xmlstarlet to:
# - `sel -t`: Select and output as a template.
# - `-m "/tasks/task"`: Match every <task> element under the root <tasks>.
# - `-v "@id"`: Print the value of the 'id' attribute.
# - `-o ": "`: Output a literal separator.
# - `-v "description"`: Print the value of the 'description' element.
# - `-n`: Print a newline.
list_tasks() {
  xmlstarlet sel -t -m "/tasks/task" -v "@id" -o ": " -v "description" -n "$PQL_FILE"
}

# Extracts all commands for a specific task ID.
#
# Uses xmlstarlet to:
# - `-m "/tasks/task[@id='$task_id']/commands/command"`: Match <command> elements
#   only within the task that has the specified 'id' attribute.
# - `-v "."`: Print the value of the current node (the command text).
get_commands() {
  local task_id="$1"
  if [[ -z "$task_id" ]]; then
    log_error "Task ID is required."
    usage
  fi
  xmlstarlet sel -t -m "/tasks/task[@id='$task_id']/commands/command" -v "." -n "$PQL_FILE"
}

# Extracts all criteria for a specific task ID.
#
# Uses xmlstarlet to:
# - `-m "/tasks/task[@id='$task_id']/criteria/criterion"`: Match <criterion> elements
#   only within the task that has the specified 'id' attribute.
get_criteria() {
  local task_id="$1"
  if [[ -z "$task_id" ]]; then
    log_error "Task ID is required."
    usage
  fi
  xmlstarlet sel -t -m "/tasks/task[@id='$task_id']/criteria/criterion" -v "." -n "$PQL_FILE"
}

# Validates the PQL file against its XSD schema.
# This ensures the XML structure is correct and all required elements/attributes are present.
validate_pql() {
  if [[ ! -f "$PQL_SCHEMA" ]]; then
    log_error "PQL schema file not found at '$PQL_SCHEMA'"
  fi
  log_info "Validating $PQL_FILE against $PQL_SCHEMA..."
  # Use `xmlstarlet val`. It returns a non-zero exit code if validation fails.
  # --err: Prints detailed error messages to stderr.
  if xmlstarlet val --err --xsd "$PQL_SCHEMA" "$PQL_FILE"; then
    log_info "$PQL_FILE is valid."
  else
    log_error "$PQL_FILE is invalid. Please check against the schema."
  fi
}

# --- Main Execution ---

# Displays help information.
usage() {
  echo "Usage: $0 <command> [task_id]"
  echo
  echo "A utility to parse and validate the PQL task file ($PQL_FILE)."
  echo
  echo "Commands:"
  echo "  validate        Validates the PQL file against its schema ($PQL_SCHEMA)"
  echo "  list            Lists all task IDs and their descriptions"
  echo "  list_by_status <status> Lists tasks filtered by a given status"
  echo "  commands <id>   Extracts all commands for a specific task ID"
  echo "  criteria <id>   Extracts all criteria for a specific task ID"
}

# Lists tasks filtered by a specific status attribute.
list_by_status() {
    local status="$1"
    if [[ -z "$status" ]]; then
        log_error "Status is required."
        usage
    fi
    # The XPath `/tasks/task[@status='$status']` selects only tasks with the matching status.
    xmlstarlet sel -t -m "/tasks/task[@status='$status']" -v "@id" -o ": " -v "description" -n "$PQL_FILE"
}

main() {
  # Ensure xmlstarlet is installed before proceeding.
  check_deps "xmlstarlet"

  if [[ ! -f "$PQL_FILE" ]]; then
    log_error "PQL file not found at '$PQL_FILE'"
  fi

  local command="${1:-}"
  shift || true # Shift arguments, ignoring error if no arguments are left

  case "$command" in
    list) list_tasks ;;
    list_by_status) list_by_status "$@" ;;
    commands) get_commands "$@" ;;
    criteria) get_criteria "$@" ;;
    validate) validate_pql ;;
    ""|--help|-h) usage ;;
    *)
      log_error "Unknown command '$command'"
      usage
      ;;
  esac
}

# This check ensures that the main function is only called when the script is
# executed directly, not when it is sourced by another script.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
