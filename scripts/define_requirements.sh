#!/bin/bash
# define_requirements.sh - Expands strategies into clear, testable requirements

set -euo pipefail
IFS=$'\n\t'

# Source utility functions
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$script_dir/utils.sh"

# Setup environment
setup_env

log_info "Checking for input strategy plan..."
if [[ ! -s "$STRATEGY_PLAN_FILE" ]]; then
    log_error "Strategy plan file is missing or empty: '$STRATEGY_PLAN_FILE'. Please run 'strategize_project.sh' first to generate it."
fi

log_info "Generating requirements from strategies..."

cat "$STRATEGY_PLAN_FILE" | "$PRISM_QUANTA_ROOT/scripts/send_prompt.sh" --prompt "From the following plan, define a list of clear, specific, and testable requirements in markdown format:" > "$REQUIREMENTS_FILE"

log_info "Requirements written to $REQUIREMENTS_FILE."
