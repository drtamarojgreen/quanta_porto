#!/bin/bash
#
# quantaporto_daemon.sh
#
# This script acts as a daemon, continuously monitoring a 'pending' queue directory for new
# task files. When a task appears, it moves it to the 'in-progress' directory and
# dispatches it to the 'quantaporto_worker.sh' script for processing.
#
# The script is designed to be robust, ensuring that tasks are not lost if a worker
# fails and preventing race conditions by atomically moving files.
#

set -euxo pipefail
IFS=$'\n\t'

# Source common utilities and environment variables
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
setup_env

log_info "QuantaPorto Daemon started."

# Ensure all necessary queue directories exist before starting the monitoring loop.
# This prevents errors if the directories were not created beforehand.
log_info "Ensuring queue directories exist..."
mkdir -p "$QUEUE_PENDING_DIR"
mkdir -p "$QUEUE_IN_PROGRESS_DIR"
mkdir -p "$QUEUE_COMPLETED_DIR"
mkdir -p "$QUEUE_FAILED_DIR"

log_info "Monitoring queue: ${QUEUE_PENDING_DIR}"

# --- Main Monitoring Loop ---
while true; do
    # Find the first file in the pending queue. The '-print -quit' arguments ensure
    # that 'find' stops after locating the very first item, making it an efficient
    # way to retrieve a single task without listing the entire directory.
    TASK_FILE=$(find "$QUEUE_PENDING_DIR" -type f -print -quit)

    # If no task file is found, the queue is empty.
    if [[ -z "$TASK_FILE" ]]; then
        # Wait for the configured polling interval before checking again.
        sleep "$POLL_INTERVAL_SEC"
        continue
    fi

    FILENAME=$(basename "$TASK_FILE")
    log_info "Found task: $FILENAME"
    
    IN_PROGRESS_PATH="${QUEUE_IN_PROGRESS_DIR}/$FILENAME"

    # Atomically move the file from 'pending' to 'in-progress'. This is a critical
    # step to prevent race conditions where multiple daemon instances might try
    # to process the same file. 'mv' is an atomic operation on the same filesystem.
    if mv "$TASK_FILE" "$IN_PROGRESS_PATH"; then
        log_info "Moved task to in-progress: $IN_PROGRESS_PATH"
        
        # Invoke the worker script to process the task. If the worker fails (exits with
        # a non-zero status), the daemon catches the failure.
        if ! bash "$(dirname "${BASH_SOURCE[0]}")/quantaporto_worker.sh" "$IN_PROGRESS_PATH"; then
            log_error "Worker script failed for task: $FILENAME"
            # To prevent losing the task, move it to the 'failed' queue for later inspection.
            mv "$IN_PROGRESS_PATH" "${QUEUE_FAILED_DIR}/$FILENAME"
            log_info "Moved task to failed queue: ${QUEUE_FAILED_DIR}/$FILENAME"
        fi
        # If the worker succeeds, it generates an action script. It is assumed that another
        # component, referred to as 'QuantaSensa', is responsible for executing this action script.
        # The original task file in 'in_progress' is left for 'QuantaLista', a hypothetical
        # cleanup utility, to manage after the action is completed or has failed.
    else
        # This condition can occur if another process moves or deletes the file between
        # the 'find' command and the 'mv' command.
        log_error "Failed to move task file, it might have been picked up by another process: $TASK_FILE"
    fi

    # If a file was processed, loop again immediately to check for more tasks
    # without waiting for the polling interval.
done
