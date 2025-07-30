#!/bin/bash
# rule_enforcer.sh - Enforces rule violations by redirecting task logic

set -euo pipefail
IFS=$'\n\t'

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Setup environment
setup_env

PROMPT_DIR="$(dirname "$PROMPT_FILE")"

VIOLATION="${1:-}"
LLM_OUTPUT="${2:-}"

# Function to safely handle file operations
safe_file_op() {
    local operation="$1"
    local file_path="$2"
    local content="${3:-}"

    case "$operation" in
        append)
            if ! echo "$content" >> "$file_path"; then
                log_error "Failed to append to $file_path"
            fi
            ;;
        *)
            log_error "Invalid file operation '$operation'"
            ;;
    esac
}

# Function to handle different consequences
handle_consequence() {
    local consequence="$1"
    local violation_type="$2"
    local severity="$3"

    case "$consequence" in
        flag_for_review)
            log_warn "Flagging for human review: $violation_type (Severity: $severity)" | tee -a "$LOG_FILE"
            ;;
        reprompt)
            log_info "Re-prompting LLM for violation: $violation_type"
            # This is a placeholder for a more sophisticated re-prompting mechanism
            safe_file_op append "$PROMPT_DIR/reprompt_queue.txt" "Original output: $LLM_OUTPUT"
            ;;
        taint)
            log_warn "Tainting LLM output for violation: $violation_type"
            # This is a placeholder for a more sophisticated tainting mechanism
            safe_file_op append "$LOG_FILE" "TAINTED_OUTPUT: $LLM_OUTPUT"
            ;;
        *)
            log_warn "Unknown consequence: $consequence"
            ;;
    esac
}

# Main function to process violations
main() {
    if [[ -z "$VIOLATION" ]]; then
        log_error "Usage: $0 <violation_type> [llm_output]"
    fi

    # Find the rule in the ethics rules file
    local rule_line=$(grep "^$VIOLATION|" "$ETHICS_RULES_FILE" || echo "")

    if [[ -z "$rule_line" ]]; then
        log_info "No enforcement action defined for violation: $VIOLATION"
        exit 0
    fi

    local severity=$(echo "$rule_line" | cut -d'|' -f2)
    local consequences_str=$(echo "$rule_line" | cut -d'|' -f4)

    # Split consequences string into an array
    IFS=',' read -r -a consequences <<< "$consequences_str"

    # Handle each consequence
    for consequence in "${consequences[@]}"; do
        handle_consequence "$consequence" "$VIOLATION" "$severity"
    done
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

main
