#!/bin/bash
#
# plan_code_tasks.sh
#
# This script implements a multi-stage, reflective pipeline for planning development
# tasks. It takes high-level requirements as input and uses an LLM to transform
# them into a prioritized and verified list of tasks.
#
# The pipeline stages are:
# 1. Gather: Checks for necessary inputs.
# 2. Infer: Uses the LLM to generate an initial list of tasks from the requirements.
# 3. Prioritize: Sorts the generated tasks by priority labels (High, Medium, Low).
# 4. Schedule: A stub for future scheduling logic.
# 5. Verify: Performs a basic format check on the tasks.
# 6. Revise: Flags ambiguous or non-compliant tasks and uses the LLM to revise them.
# 7. Summary: Displays the final and revised task lists.
#

set -euo pipefail
IFS=$'\n\t'

# Source utility functions and environment variables
source "$(dirname "$0")/utils.sh"
setup_env

# --- File and Prompt Definitions ---
# Map environment variables to local script variables for clarity.
INPUT="$REQUIREMENTS_FILE"
ENGINE="$LLM_INFER_SCRIPT"
RAW_OUTPUT="$TASK_LIST_RAW_FILE"
TMP="$TASK_TMP_FILE"
FINAL_OUTPUT="$TASK_LIST_FINAL_FILE"
FLAGGED="$FLAGGED_TASKS_FILE"
REVISED_OUTPUT="$TASK_LIST_REVISED_FILE"

# Prompts used to guide the LLM at different stages.
PROMPT="Break these requirements into modular development tasks with priority labels (High Priority, Medium Priority, Low Priority):"
REVISION_PROMPT="The following tasks are ambiguous or violate project rules. Revise them for clarity, specificity, and full compliance:"

log_info "Starting reflective planning pipeline..."

# --- Pipeline Stages ---

# Stage 1: Gather inputs and verify prerequisites.
gather() {
  log_info "Gather Stage: Checking inputs..."
  if [[ ! -f "$INPUT" ]]; then
    log_error "Missing input file: $INPUT"
  fi
  if [[ ! -x "$ENGINE" ]]; then
    log_error "LLM engine script not executable: $ENGINE"
  fi
  log_info "Gather Stage: Inputs are ready."
}

# Stage 2: Run initial inference to generate tasks from requirements.
infer() {
  log_info "Infer Stage: Running initial inference..."
  cat "$INPUT" | "$PRISM_QUANTA_ROOT/scripts/send_prompt.sh" --prompt "$PROMPT" > "$RAW_OUTPUT"
  log_info "Infer Stage: Raw tasks written to $RAW_OUTPUT"
}

# Stage 3: Prioritize tasks by sorting them based on priority labels.
prioritize() {
  log_info "Prioritize Stage: Sorting tasks by priority..."
  # Use grep to find lines with priority labels and append them to a temporary file
  # in the desired order. `|| true` prevents the script from exiting if no tasks
  # of a certain priority are found.
  grep -i 'High Priority' "$RAW_OUTPUT" > "$TMP" || true
  grep -i 'Medium Priority' "$RAW_OUTPUT" >> "$TMP" || true
  grep -i 'Low Priority' "$RAW_OUTPUT" >> "$TMP" || true
  # Overwrite the final output file with the sorted list.
  mv "$TMP" "$FINAL_OUTPUT"
  log_info "Prioritize Stage: Prioritized tasks saved to $FINAL_OUTPUT"
}

# Stage 4: A placeholder for future scheduling logic.
schedule() {
  log_info "Schedule Stage: Stubbed for now."
  # This could be expanded to include effort estimates, dependencies, or target dates.
}

# Stage 5: Perform a simple verification check on the task format.
verify() {
  log_info "Verify Stage: Checking for incomplete items..."
  # This `grep` pipeline looks for lines that start with a hyphen (like a list item)
  # but do not contain any letters, which might indicate an empty or malformed task.
  grep -E '^-' "$FINAL_OUTPUT" | grep -v '[a-zA-Z]' && log_warn "Incomplete task found."
  log_info "Verify Stage: Format check complete."
}

# Stage 6: Revise tasks by flagging and re-processing ambiguous or non-compliant items.
revise() {
  log_info "Revise Stage: Scanning for ambiguity and rule violations..."

  # Flag tasks containing ambiguous verbs or vague scope definitions.
  grep -Ei 'handle|optimize|improve|support|refactor|update logic|better UX|efficiency|flexibility' "$FINAL_OUTPUT" > "$FLAGGED" || true

  # Flag tasks that violate a known rule (e.g., no deleting test files).
  grep -Ei 'delete.*test' "$FINAL_OUTPUT" >> "$FLAGGED" || true

  # If any tasks were flagged, send them back to the LLM for revision.
  if [[ -s "$FLAGGED" ]]; then
    log_info "Revise Stage: Flagged tasks found that require clarification."
    log_info "Re-running LLM to revise flagged tasks..."
    # Pipe the flagged tasks to the LLM with a specific revision prompt.
    cat "$FLAGGED" | "$ENGINE" --prompt "$REVISION_PROMPT" > "$REVISED_OUTPUT"
    log_info "Revise Stage: Revised tasks saved to $REVISED_OUTPUT"
  else
    log_info "Revise Stage: No flagged items found."
  fi
}

# Stage 7: Display a summary of the final and revised task lists.
summary() {
  log_info "--- Planning Summary ---"
  log_info "Finalized task list is in: $FINAL_OUTPUT"
  if [[ -s "$REVISED_OUTPUT" ]]; then
    log_info "Revised tasks needing review are in: $REVISED_OUTPUT"
  fi
}

# --- Pipeline Execution ---
gather
infer
prioritize
schedule
verify
revise
summary
log_info "Reflective planning pipeline complete."
