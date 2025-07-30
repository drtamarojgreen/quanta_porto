#!/bin/bash
# plan_code_tasks.sh – Multi-stage reflective planner for QuantaPorto

set -euo pipefail
IFS=$'\n\t'

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Setup environment
setup_env

# Map environment variables to the script's expected variable names
INPUT="$REQUIREMENTS_FILE"
ENGINE="$LLM_INFER_SCRIPT"
RAW_OUTPUT="$TASK_LIST_RAW_FILE"
TMP="$TASK_TMP_FILE"
FINAL_OUTPUT="$TASK_LIST_FINAL_FILE"
FLAGGED="$FLAGGED_TASKS_FILE"
REVISED_OUTPUT="$TASK_LIST_REVISED_FILE"

PROMPT="Break requirements into modular dev tasks with priority labels:"
REVISION_PROMPT="Revise tasks for clarity and rule compliance:"

log_info "Starting reflective planning pipeline..."

gather() {
  log_info "Checking input..."
  if [ ! -f "$INPUT" ]; then
    log_error "Missing input file: $INPUT"
  fi
  if [ ! -x "$ENGINE" ]; then
    log_error "LLM engine script not executable: $ENGINE"
  fi
  log_info "Found $INPUT and engine is ready."
}

infer() {
  log_info "Running initial inference..."
  cat "$INPUT" | "$PRISM_QUANTA_ROOT/scripts/send_prompt.sh" --prompt "$PROMPT" > "$RAW_OUTPUT"
  log_info "Raw tasks written to $RAW_OUTPUT"
}

prioritize() {
  log_info "Sorting by priority labels..."
  grep -i 'High Priority' "$RAW_OUTPUT" > "$TMP" || true
  grep -i 'Medium Priority' "$RAW_OUTPUT" >> "$TMP" || true
  grep -i 'Low Priority' "$RAW_OUTPUT" >> "$TMP" || true
  mv "$TMP" "$FINAL_OUTPUT"
  log_info "Prioritized tasks saved to $FINAL_OUTPUT"
}

schedule() {
  log_info "Scheduling pass (stubbed for now)..."
  # You can expand this with effort estimates or dates later
}

verify() {
  log_info "Checking for incomplete items..."
  grep -E '^-' "$FINAL_OUTPUT" | grep -v '[a-zA-Z]' && log_warn "Incomplete task found"
  log_info "Format check complete."
}

revise() {
  log_info "Scanning for ambiguity and rule violations..."

  # Flag ambiguous verbs or vague scope
  grep -Ei 'handle|optimize|improve|support|refactor|update logic|better UX|efficiency|flexibility' "$FINAL_OUTPUT" > "$FLAGGED" || true

  # Flag rule violations (example: deletion of test files)
  grep -Ei 'delete.*test' "$FINAL_OUTPUT" >> "$FLAGGED" || true

  if [ -s "$FLAGGED" ]; then
    log_info "Flagged tasks found:"
    cat "$FLAGGED"
    log_info "Re-running LLM for clarification..."
    cat "$FLAGGED" | "$ENGINE" --prompt "$REVISION_PROMPT" > "$REVISED_OUTPUT"
    log_info "Revised tasks saved to $REVISED_OUTPUT"
  else
    log_info "No flagged items found."
  fi
}

summary() {
  log_info "Finalized task list:"
  cat "$FINAL_OUTPUT"
  if [ -s "$REVISED_OUTPUT" ]; then
    echo ""
    log_info "Revised tasks available for review:"
    cat "$REVISED_OUTPUT"
  fi
}

# Pipeline execution
gather
infer
prioritize
schedule
verify
revise
summary
