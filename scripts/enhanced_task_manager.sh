#!/bin/bash
# enhanced_task_manager.sh - Advanced runner for scheduled tasks with integrated ethics checking.

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

    while (( attempt <= max_retries )); do
        log_info "Running inference for the task (Attempt ${attempt}/${max_retries})..."
        llm_output=$("$(dirname "$0")/run_inference.sh" "$task_prompt")

        if [[ -z "$llm_output" ]]; then
            log_warn "LLM inference returned an empty response on attempt ${attempt}."
            append_to_log "TASK_MANAGER: WARN - LLM returned empty response on attempt ${attempt}."
            ((attempt++))
            sleep 1
            continue
        fi
        append_to_log "TASK_MANAGER: LLM inference successful on attempt ${attempt}."

        # 2. Ethics Check
        log_info "Performing ethics and bias check on LLM output..."
        local ethics_output
        ethics_output=$("$(dirname "$0")/ethics_bias_checker.sh" --text "$llm_output" --json)

        local ethics_status
        ethics_status=$(echo "$ethics_output" | jq -r '.status')

        if [[ "$ethics_status" == "pass" ]]; then
            append_to_log "TASK_MANAGER: Ethics check passed."
            log_info "Task completed successfully."
            append_to_log "TASK_MANAGER: Task completed."
            echo "$llm_output"
            exit 0
        fi

        # Ethics check failed, trigger rule enforcer
        log_warn "Ethics check failed on attempt ${attempt}. Triggering rule enforcer."
        append_to_log "TASK_MANAGER: WARN - Ethics check failed on attempt ${attempt}."

        # Get the primary violation to pass to the enforcer
        local primary_violation
        primary_violation=$(echo "$ethics_output" | jq -r '.violations[0]')

        if [[ -n "$primary_violation" && "$primary_violation" != "null" ]]; then
            "$(dirname "$0")/rule_enforcer.sh" "$primary_violation" "$llm_output"
        fi

        ((attempt++))
    done

    log_error "Task failed after ${max_retries} attempts due to persistent ethics violations."
    append_to_log "TASK_MANAGER: ERROR - Task failed after ${max_retries} attempts."
    exit 2 # Use a specific exit code for ethics failure
}

main "$@"

    if [[ -z "$llm_output" ]]; then
        log_error "LLM inference returned an empty response."
        append_to_log "TASK_MANAGER: ERROR - LLM returned empty response."
        exit 1
    fi
    append_to_log "TASK_MANAGER: LLM inference successful."

    # 2. Ethics Check
    log_info "Performing ethics and bias check on LLM output..."
    if ! output=$("$(dirname "$0")/ethics_bias_checker.sh" --text "$llm_output" --json); then
        log_warn "Ethics check failed. See ethics log for details."
        append_to_log "TASK_MANAGER: WARN - Ethics check failed."
        # In a future step, this could trigger rule_enforcer.sh
        echo "$llm_output" # Still output the tainted result for logging/review
        exit 2 # Use a specific exit code for ethics failure
    fi
    append_to_log "TASK_MANAGER: Ethics check passed."

    # 3. Output final result
    log_info "Task completed successfully."
    append_to_log "TASK_MANAGER: Task completed."
    echo "$llm_output"
}

main "$@"