#!/bin/bash
# strategize_project.sh - Converts goals into logical strategies

set -euo pipefail
IFS=$'\n\t'

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Setup environment
setup_env

log_info "Reading goals from $PROJECT_GOALS_FILE..."

if [[ ! -f "$PROJECT_GOALS_FILE" ]]; then
    log_error "No project goals file found!"
fi

cat "$PROJECT_GOALS_FILE" | "$PRISM_QUANTA_ROOT/scripts/send_prompt.sh" --prompt "Break these goals into sub-strategies:" > "$STRATEGY_PLAN_FILE"

log_info "Plan saved to $STRATEGY_PLAN_FILE."
