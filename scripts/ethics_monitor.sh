#!/bin/bash
#
# ethics_monitor.sh
#
# This script acts as a daemon to continuously monitor LLM output for potential
# ethics violations. It "tails" a specified output file, and for each new line
# added, it checks the content against a set of rules defined in the ethics rules file.
# If a potential violation is found, it invokes the 'rule_enforcer.sh' script.
#
# This script is intended to be run as a long-running background process.
#
# Dependencies: tail
#

set -euo pipefail
IFS=$'\n\t'

# Source utility functions and environment variables
source "$(dirname "$0")/utils.sh"
setup_env

# Checks a given line of output against all defined ethics rules.
#
# For each rule in the ethics rules file, it performs a simple string search.
# If the "condition" string from a rule is found within the LLM output,
# it triggers the rule enforcer script, passing the corresponding rule ID.
#
#   $1: The line of LLM output to check.
check_for_violations() {
    local output="$1"

    # Read the ethics rules file line by line, skipping the header.
    # `tail -n +2` starts reading from the second line of the file.
    # The `while IFS='|' read ...` command parses the pipe-delimited columns.
    while IFS='|' read -r rule_id severity condition consequence; do
        # This is a placeholder for a more sophisticated condition matching engine.
        # For now, we'll just check if the output contains the condition string.
        # The `*...*` pattern match is a simple substring check.
        if [[ "$output" == *"$condition"* ]]; then
            log_warn "Potential violation detected: '$condition' (Rule: $rule_id)"
            # Violation detected, call the rule enforcer to handle the consequences.
            "$RULE_ENFORCER_SCRIPT" "$rule_id" "$output"
        fi
    done < <(tail -n +2 "$ETHICS_RULES_FILE") # Process substitution is used to pipe tail's output to the loop
}

# Main monitoring loop.
main() {
    log_info "Starting ethics monitor for file: $LLM_OUTPUT_FILE"
    # Create the output file if it doesn't exist to prevent tail from failing.
    touch "$LLM_OUTPUT_FILE"

    # Monitor the output file for new lines.
    # - `tail -f`: Follow the file, outputting new data as it's added.
    # - `-n 0`: Start from the end of the file, only showing new lines.
    # The output of `tail` is piped into a `while read` loop, which processes
    # each new line as it appears.
    tail -f -n 0 "$LLM_OUTPUT_FILE" | while read -r line; do
        log_info "New LLM output detected, checking for violations..."
        check_for_violations "$line"
    done
}

main
