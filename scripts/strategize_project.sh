#!/bin/bash
#
# strategize_project.sh
#
# This script automates the initial project strategy phase. It reads a list of
# high-level goals from a specified file, sends them to the LLM, and prompts
# the model to break them down into a set of actionable sub-strategies.
#
# The resulting strategic plan is saved to a separate file for further processing
# or review.
#
# Usage: ./strategize_project.sh
#
# Environment Variables:
#   - PROJECT_GOALS_FILE: Path to the file containing project goals.
#   - STRATEGY_PLAN_FILE: Path where the output strategy plan will be saved.
#

set -euo pipefail
IFS=$'\n\t'

# Source utility functions and environment variables
source "$(dirname "$0")/utils.sh"
setup_env

log_info "Reading goals from $PROJECT_GOALS_FILE..."

# Ensure the goals file exists before attempting to read it.
if [[ ! -f "$PROJECT_GOALS_FILE" ]]; then
    log_error "Project goals file not found at: $PROJECT_GOALS_FILE"
fi

# 1. Read the project goals file using `cat`.
# 2. Pipe the content to the `send_prompt.sh` script.
# 3. Use the `--prompt` argument to instruct the LLM on how to process the goals.
# 4. Redirect the final output from the LLM to the strategy plan file.
cat "$PROJECT_GOALS_FILE" | "$PRISM_QUANTA_ROOT/scripts/send_prompt.sh" --prompt "Break these goals into sub-strategies:" > "$STRATEGY_PLAN_FILE"

log_info "Strategic plan saved to $STRATEGY_PLAN_FILE."
