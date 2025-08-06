#!/bin/bash
# quantaporto_daemon.sh - Monitors the pending queue and dispatches tasks to the worker.

set -euxo pipefail
IFS=$'\n\t'

# Source environment
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
setup_env

log_info "QuantaPorto Daemon started."

# Ensure all queue directories exist before starting
log_info "Ensuring queue directories exist..."
mkdir -p "$QUEUE_PENDING_DIR"
mkdir -p "$QUEUE_IN_PROGRESS_DIR"
mkdir -p "$QUEUE_COMPLETED_DIR"
mkdir -p "$QUEUE_FAILED_DIR"

log_info "Monitoring queue: ${QUEUE_PENDING_DIR}"

while true; do
    # Find the first file in the pending queue. '-print -quit' is a safe way to get one file.
    TASK_FILE=$(find "$QUEUE_PENDING_DIR" -type f -print -quit)

    if [[ -z "$TASK_FILE" ]]; then
        # No tasks, wait for the next poll
        sleep "$POLL_INTERVAL_SEC"
        continue
    fi

    FILENAME=$(basename "$TASK_FILE")
    log_info "Found task: $FILENAME"
    
    IN_PROGRESS_PATH="${QUEUE_IN_PROGRESS_DIR}/$FILENAME"

    # Atomically move the file to the in-progress directory
    if mv "$TASK_FILE" "$IN_PROGRESS_PATH"; then
        log_info "Moved task to in-progress: $IN_PROGRESS_PATH"
        
        # Invoke the worker script. If it fails, log the error and move the task to failed.
        if ! bash "$(dirname "${BASH_SOURCE[0]}")/quantaporto_worker.sh" "$IN_PROGRESS_PATH"; then
            log_error "Worker script failed for task: $FILENAME"
            # Move the task to the failed queue so it's not lost
            mv "$IN_PROGRESS_PATH" "${QUEUE_FAILED_DIR}/$FILENAME"
            log_info "Moved task to failed queue: ${QUEUE_FAILED_DIR}/$FILENAME"
        fi
        # If the worker succeeds, it's QuantaSensa's job to handle the corresponding action script.
        # The original task file in 'in_progress' will be cleaned up later by QuantaLista
        # once the entire action is completed or failed.
    else
        log_error "Failed to move task file, it might have been picked up by another process: $TASK_FILE"
    fi

    # Don't sleep if we processed a file, check for more immediately.
done
