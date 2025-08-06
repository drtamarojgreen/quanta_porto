#!/bin/bash
#
# polling.sh
#
# This script is a simple command runner that executes a given command in the
# background while displaying a "thinking" indicator (a series of dots) to the
# user. It captures the output of the command and prints it to stdout once
# the command is complete.
#
# This is useful for long-running processes, like LLM inference, where providing
# visual feedback is desirable.
#
# Usage: ./polling.sh <command_and_arguments>
#
# Example:
#   ./polling.sh sleep 5
#

set -euo pipefail
IFS=$'\n\t'

# The command to be executed is passed as arguments to this script.
COMMAND_TO_RUN="$@"
if [[ -z "$COMMAND_TO_RUN" ]]; then
    echo "Usage: $0 <command>" >&2
    exit 1
fi

# Create temporary files to store the output and process ID (PID) of the
# background command. Using `mktemp` is a secure way to create temp files.
OUTPUT_FILE=$(mktemp)
PID_FILE=$(mktemp)

# --- Cleanup Trap ---
# This trap ensures that the temporary files are removed when the script exits,
# regardless of whether it finishes successfully, is interrupted (Ctrl+C), or fails.
cleanup() {
    rm -f "$OUTPUT_FILE" "$PID_FILE"
}
trap cleanup EXIT

# Execute the command in the background.
# `>` redirects stdout to the output file.
# `2>&1` redirects stderr to the same place as stdout.
# `&` runs the process in the background.
# `$!` is a special shell variable that holds the PID of the last backgrounded command.
$COMMAND_TO_RUN > "$OUTPUT_FILE" 2>&1 &
echo $! > "$PID_FILE"

PID=$(cat "$PID_FILE")

# --- Polling Loop ---
# This loop checks if the background process is still running.
# `ps -p $PID` will succeed (exit code 0) as long as the process exists.
while ps -p $PID > /dev/null; do
    echo -n "." >&2 # Print a dot to stderr to show progress
    sleep 1
done

# Once the command completes, print a newline to move past the dots.
echo >&2

# Print the captured output of the command.
cat "$OUTPUT_FILE"
