#!/bin/bash
# polling.sh - Periodically run ethics and bias checks

set -euo pipefail
IFS=$'\n\t'

# Determine project root if not already set, making the script more portable.
if [[ -z "${PRISM_QUANTA_ROOT:-}" ]]; then
    PRISM_QUANTA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
fi

# Generate and source the environment file
ENV_SCRIPT="/tmp/quantaporto_env_polling.sh"
"$PRISM_QUANTA_ROOT/scripts/generate_env.sh" "$PRISM_QUANTA_ROOT/environment.txt" "$ENV_SCRIPT" "$PRISM_QUANTA_ROOT"
source "$ENV_SCRIPT"

# Executes a command in the background and shows a "thinking" message
# while waiting for it to complete.
#
# Usage: ./polling.sh <command>
#

COMMAND_TO_RUN="$@"
OUTPUT_FILE=$(mktemp)
PID_FILE=$(mktemp)

# Run the command in the background
$COMMAND_TO_RUN > "$OUTPUT_FILE" 2>&1 &
echo $! > "$PID_FILE"

PID=$(cat "$PID_FILE")

while ps -p $PID > /dev/null; do
    echo -n "."
    sleep 1
done

echo
cat "$OUTPUT_FILE"
rm "$OUTPUT_FILE"
rm "$PID_FILE"

# Function to check for violations
check_for_violations() {
    if [ ! -f "$POLLING_LLM_OUTPUT_FILE" ]; then
        log_warn "LLM output file not found: $POLLING_LLM_OUTPUT_FILE"
        return
    fi

    local llm_output
    llm_output=$(cat "$POLLING_LLM_OUTPUT_FILE")

    while IFS='|' read -r rule_id condition consequence; do
        if [[ -n "$rule_id" && ! "$rule_id" =~ ^# ]]; then
            if echo "$llm_output" | grep -q "$condition"; then
                log_warn "Violation detected: $rule_id" | tee -a "$ETHICS_VIOLATIONS_LOG"
                "$RULE_ENFORCER_SCRIPT" "$rule_id"
            fi
        fi
    done < "$ETHICS_RULES_FILE"
}

# Main polling loop
main() {
    while true; do
        log_info "Running ethics and bias checks..."
        check_for_violations
        log_info "Checks complete. Sleeping for 60 seconds..."
        sleep 60
    done
}

main
