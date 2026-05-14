#!/bin/bash
#
# enhanced_task_manager.sh
#
# This script serves as an advanced runner for processing tasks that require LLM inference.
# It orchestrates a multi-step process:
#   1. Runs the LLM inference.
#   2. Performs a rigorous ethics and bias check on the output.
#   3. If the check fails, it triggers the rule enforcer and retries the inference.
#   4. If the check passes, it returns the successful output.
#
# The script includes a retry mechanism to handle transient LLM failures or to give
# the system a chance to produce a compliant response after rule enforcement.
#
# Usage: ./enhanced_task_manager.sh <task_prompt>
#        or
#        cat <prompt_file> | ./enhanced_task_manager.sh
#

set -euo pipefail
IFS=$'\n\t'

# Source utility functions and environment
source "$(dirname "$0")/utils.sh"
setup_env

# --- Dependencies ---
check_deps "jq"

# --- Main Logic ---
main() {
    local task_prompt
    # Read prompt from the first argument or from stdin if piped.
    if [[ -n "${1:-}" ]]; then
        task_prompt="$1"
    elif ! [[ -t 0 ]]; then
        task_prompt=$(cat)
    else
        log_error "Usage: $0 <task_prompt> or pipe prompt into script."
    fi

    log_info "Starting enhanced task management for prompt..."
    append_to_log "TASK_MANAGER: Received new task."

    local llm_output
    local attempt=1
    local max_retries=${MAX_RETRIES:-3}

    # --- Main Retry Loop ---
    # This loop will attempt the task up to 'max_retries' times.
    while (( attempt <= max_retries )); do
        log_info "Running inference for the task (Attempt ${attempt}/${max_retries})..."

        # 1. Run Inference
        llm_output=$("$(dirname "$0")/run_inference.sh" "$task_prompt")

        # Handle cases where the LLM returns nothing.
        if [[ -z "$llm_output" ]]; then
            log_warn "LLM inference returned an empty response on attempt ${attempt}."
            append_to_log "TASK_MANAGER: WARN - LLM returned empty response on attempt ${attempt}."
            ((attempt++))
            sleep 1 # Wait a moment before retrying
            continue
        fi
        append_to_log "TASK_MANAGER: LLM inference successful on attempt ${attempt}."

        # 2. Ethics and Bias Check
        log_info "Performing ethics and bias check on LLM output..."
        local ethics_output
        ethics_output=$("$(dirname "$0")/ethics_bias_checker.sh" --text "$llm_output" --json)

        # Parse the status from the JSON output of the checker.
        local ethics_status
        ethics_status=$(echo "$ethics_output" | jq -r '.status')

        # If the check passes, the task is successful.
        if [[ "$ethics_status" == "pass" ]]; then
            append_to_log "TASK_MANAGER: Ethics check passed."
            log_info "Task completed successfully."
            append_to_log "TASK_MANAGER: Task completed."
            echo "$llm_output"
            exit 0
        fi

        # 3. Handle Ethics Failure
        log_warn "Ethics check failed on attempt ${attempt}. Triggering rule enforcer."
        append_to_log "TASK_MANAGER: WARN - Ethics check failed on attempt ${attempt}."

        # Extract the primary violation to pass to the rule enforcer.
        local primary_violation
        primary_violation=$(echo "$ethics_output" | jq -r '.violations[0]')

        # Trigger the enforcer if a violation was found.
        if [[ -n "$primary_violation" && "$primary_violation" != "null" ]]; then
            "$(dirname "$0")/rule_enforcer.sh" "$primary_violation" "$llm_output"
        fi

        ((attempt++))
    done

    # If the loop finishes without success, the task has failed.
    log_error "Task failed after ${max_retries} attempts due to persistent ethics violations."
    append_to_log "TASK_MANAGER: ERROR - Task failed after ${max_retries} attempts."
    exit 2 # Use a specific exit code for ethics failure
}

main "$@"