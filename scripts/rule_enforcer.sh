#!/bin/bash
#
# rule_enforcer.sh
#
# This script is responsible for enforcing actions based on rule violations detected
# in LLM outputs. It takes a violation type as input, looks up the corresponding
# rule in the ethics rules file, and triggers one or more consequences, such as
# flagging for review, re-prompting, or tainting the output.
#
# The rules file is expected to be a pipe-delimited file where the first column
# is the violation type.
#
# Usage: ./rule_enforcer.sh <violation_type> [llm_output]
#

set -euo pipefail
IFS=$'\n\t'

# Source utility functions and environment variables
source "$(dirname "$0")/utils.sh"
setup_env

PROMPT_DIR="$(dirname "$PROMPT_FILE")"

# --- Input Arguments ---
VIOLATION="${1:-}"
LLM_OUTPUT="${2:-}" # The problematic LLM output, used by some consequences

# Function to safely handle file append operations.
# This provides a centralized point for file I/O with error handling.
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

# Dispatches actions based on the specified consequence type.
# Each case represents a different strategy for handling a rule violation.
handle_consequence() {
    local consequence="$1"
    local violation_type="$2"
    local severity="$3"

    case "$consequence" in
        flag_for_review)
            log_warn "Flagging for human review: $violation_type (Severity: $severity)"
            append_to_log "RULE_ENFORCER: Flagged for review: $violation_type (Severity: $severity)"
            ;;
        reprompt)
            log_info "Queueing for re-prompting due to violation: $violation_type"
            # This is a placeholder for a more sophisticated re-prompting mechanism.
            # It appends the problematic output to a queue file for another process to handle.
            safe_file_op append "$PROMPT_DIR/reprompt_queue.txt" "Original output: $LLM_OUTPUT"
            ;;
        taint)
            log_warn "Tainting LLM output for violation: $violation_type"
            # Tainting marks the output as unreliable. Here, it's logged for traceability.
            safe_file_op append "$LOG_FILE" "TAINTED_OUTPUT: $LLM_OUTPUT"
            ;;
        *)
            log_warn "Unknown consequence defined in rules: '$consequence'"
            ;;
    esac
}

# Main function to process violations.
main() {
    if [[ -z "$VIOLATION" ]]; then
        log_error "Usage: $0 <violation_type> [llm_output]"
    fi

    # Find the corresponding rule in the ethics rules file.
    # The file is expected to be pipe-delimited, e.g., "bias_detection|high|...|reprompt,flag_for_review"
    # `grep || echo ""` ensures the command doesn't fail if no line is found.
    local rule_line
    rule_line=$(grep "^$VIOLATION|" "$ETHICS_RULES_FILE" || echo "")

    # If no rule is found for the given violation, exit gracefully.
    if [[ -z "$rule_line" ]]; then
        log_info "No enforcement action defined for violation: $VIOLATION"
        exit 0
    fi

    # Parse the rule line to extract severity and consequences.
    local severity
    severity=$(echo "$rule_line" | cut -d'|' -f2)
    local consequences_str
    consequences_str=$(echo "$rule_line" | cut -d'|' -f4)

    # Split the comma-separated consequences string into a bash array.
    IFS=',' read -r -a consequences <<< "$consequences_str"

    # Iterate over the consequences and handle each one.
    for consequence in "${consequences[@]}"; do
        handle_consequence "$consequence" "$VIOLATION" "$severity"
    done
}

# Ensure the directory for the main log file exists before trying to write to it.
mkdir -p "$(dirname "$LOG_FILE")"

main
