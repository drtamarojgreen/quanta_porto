#!/bin/bash
#
# code_analysis.sh
#
# This script performs a comprehensive static analysis of the project's codebase
# and generates a detailed report in Markdown format. It provides insights into
# various aspects of the project's health, including test coverage, documentation
# status, code cleanliness, and potential technical debt.
#
# The analysis includes:
# - Counting automated tests (PQL, Ethics, BDD).
# - Checking the status of the documentation directory.
# - Identifying orphaned (untracked) files in the repository.
# - Scanning for "TODO" comments in shell scripts.
# - Finding files that are only referenced in the environment configuration.
#

set -euo pipefail
IFS=$'\n\t'

# Source utility functions and environment variables
source "$(dirname "$0")/utils.sh"
setup_env

# --- Configuration ---
# Provide default paths for key files if they are not set in the environment.
: "${CODE_ANALYSIS_REPORT_FILE:="memory/code_analysis_report.md"}"
: "${PQL_TESTS_XML_FILE:="rules/pql_tests.xml"}"
: "${ETHICS_AND_BIAS_TESTS_XML_FILE:="rules/ethics_and_bias_tests.xml"}"

# --- Dependency Check ---
check_deps "git" "find" "grep" "wc" "stat"

# --- Analysis Functions ---

# Initializes the report file by clearing it and adding a header.
generate_report_header() {
    log_info "Starting comprehensive code analysis..."
    mkdir -p "$(dirname "$CODE_ANALYSIS_REPORT_FILE")"
    {
        echo "# Code Analysis Report"
        echo "Generated on: $(date)"
        echo "---"
    } > "$CODE_ANALYSIS_REPORT_FILE"
}

# Analyzes and reports the number of automated tests of different types.
analyze_test_counts() {
    log_info "Analyzing test counts..."

    # Count PQL tests by looking for <test> tags in the XML file.
    local pql_test_count=0
    if [[ -f "$PQL_TESTS_XML_FILE" ]]; then
        pql_test_count=$(grep -c "<test " "$PQL_TESTS_XML_FILE" || echo 0)
    fi

    # Count ethics tests by looking for <task> tags in their XML file.
    local ethics_test_count=0
    if [[ -f "$ETHICS_AND_BIAS_TESTS_XML_FILE" ]]; then
        ethics_test_count=$(grep -c "<task " "$ETHICS_AND_BIAS_TESTS_XML_FILE" || echo 0)
    fi

    # Count BDD scenarios by finding all .feature files and counting "Scenario:" lines.
    local bdd_scenario_count=0
    local features_dir="$PRISM_QUANTA_ROOT/tests/bdd/features"
    if [[ -d "$features_dir" ]]; then
        bdd_scenario_count=$(find "$features_dir" -type f -name "*.feature" -print0 | xargs -0 grep -c -E '^[[:space:]]*Scenario:' || echo 0)
    fi

    local total_tests=$((pql_test_count + ethics_test_count + bdd_scenario_count))

    # Append the test metrics to the report.
    {
        echo "## Project Test Metrics"
        echo
        echo "- **PQL Test Cases:** $pql_test_count"
        echo "- **Ethics & Bias Test Cases:** $ethics_test_count"
        echo "- **BDD Scenarios:** $bdd_scenario_count"
        echo "- **Total Automated Tests:** $total_tests"
        echo
        echo "---"
    } >> "$CODE_ANALYSIS_REPORT_FILE"
}

# Checks the last modification time of the documentation directory.
analyze_docs_status() {
    log_info "Analyzing documentation status..."
    local docs_dir="$PRISM_QUANTA_ROOT/docs"
    local last_modified="Directory not found."

    if [[ -d "$docs_dir" ]]; then
        # Use `stat` to get the last modification time. Note: The `-c %y` flag is for GNU/Linux.
        # macOS/BSD would require a different flag, e.g., `stat -f %Sm`.
        if command -v stat &> /dev/null; then
            last_modified=$(stat -c %y "$docs_dir")
        else
            last_modified="stat command not found, cannot determine modification time."
        fi
    fi

    {
        echo "## Documentation Status"
        echo
        echo "- **Docs Directory Last Modified:** $last_modified"
        echo
        echo "---"
    } >> "$CODE_ANALYSIS_REPORT_FILE"
}

# Finds all files in the repository that are not tracked by Git.
analyze_orphaned_files() {
    log_info "Checking for orphaned (untracked) files..."
    # `git ls-files --others --exclude-standard` is the standard way to find untracked files.
    local orphaned_files
    orphaned_files=$(git ls-files --others --exclude-standard)

    {
        echo "## Orphaned File Analysis"
        echo
        if [[ -n "$orphaned_files" ]];
            echo "Found untracked files. These might be temporary files, logs, or new files that need to be committed or added to \`.gitignore\`:"
            echo '```'
            echo "$orphaned_files"
            echo '```'
        else
            echo "No orphaned or untracked files found in the repository."
        fi
        echo
        echo "---"
    } >> "$CODE_ANALYSIS_REPORT_FILE"
}

# Scans all shell scripts for "TODO" comments and lists them in the report.
analyze_todos() {
    log_info "Scanning for TODO comments in shell scripts..."
    {
        echo "## TODOs in Scripts"
        echo
    } >> "$CODE_ANALYSIS_REPORT_FILE"

    local found_any_todos=false
    # Use `find` to locate all .sh files, then pipe them to a while loop for processing.
    find "$PRISM_QUANTA_ROOT" -type f -name "*.sh" -not -path "*/.git/*" -print0 | while IFS= read -r -d '' script_file; do
        local relative_path="${script_file#$PRISM_QUANTA_ROOT/}"

        # `grep -n` includes the line number in the output.
        if todo_findings=$(grep -n "TODO" "$script_file" || true); then
            if [[ -n "$todo_findings" ]]; then
                found_any_todos=true
                {
                    echo "### \`$relative_path\`"
                    echo '```'
                    echo "$todo_findings"
                    echo '```'
                    echo
                } >> "$CODE_ANALYSIS_REPORT_FILE"
            fi
        fi
    done

    if [[ "$found_any_todos" == "false" ]]; then
        echo "No TODO comments found in any shell scripts." >> "$CODE_ANALYSIS_REPORT_FILE"
    fi
     echo >> "$CODE_ANALYSIS_REPORT_FILE"
}
# Identifies files defined in `environment.txt` that are not referenced anywhere else.
analyze_environment_only_references() {
    log_info "Checking for files only referenced in environment.txt..."
    {
        echo "## Environment File Reference Analysis"
        echo
    } >> "$CODE_ANALYSIS_REPORT_FILE"

    # Extract all file paths from environment.txt.
    # This regex looks for keys ending in _FILE or _PATH and extracts their values.
    local config_files
    config_files=$(grep -E '^[^#]*(_FILE|_PATH)[[:space:]]*=' "$PRISM_QUANTA_ROOT/environment.txt" | \
                   sed -e 's/.*=[[:space:]]*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | \
                   grep -v -E '^\.$' || true)

    if [[ -z "$config_files" ]]; then
        echo "No file paths found in \`environment.txt\` to analyze." >> "$CODE_ANALYSIS_REPORT_FILE"
        echo -e "\n---" >> "$CODE_ANALYSIS_REPORT_FILE"
        return
    fi

    local lonely_files=""
    local all_tracked_files
    all_tracked_files=$(git ls-files)

    for file_path in $config_files; do
        [[ -f "$PRISM_QUANTA_ROOT/$file_path" ]] || continue # Skip if the file doesn't exist

        local file_basename
        file_basename=$(basename "$file_path")

        # Search for the file's basename in all tracked files, excluding environment.txt itself.
        # `grep -Fq` performs a quiet, fixed-string search.
        if ! echo "$all_tracked_files" | grep -v "environment.txt" | xargs -r --no-run-if-empty grep -Fq "$file_basename"; then
            lonely_files+="- \`$file_path\`\n"
        fi
    done

    if [[ -n "$lonely_files" ]]; then
        {
            echo "Found files that seem to be referenced only in \`environment.txt\`. These might be part of a deprecated feature or no longer in use:"
            echo
            echo -e "$lonely_files"
        } >> "$CODE_ANALYSIS_REPORT_FILE"
    else
        echo "All file paths defined in \`environment.txt\` appear to be referenced elsewhere in the codebase." >> "$CODE_ANALYSIS_REPORT_FILE"
    fi

    echo "---" >> "$CODE_ANALYSIS_REPORT_FILE"
}

# --- Main Execution ---

main() {
    generate_report_header
    analyze_test_counts
    analyze_docs_status
    analyze_orphaned_files
    analyze_todos
    analyze_environment_only_references
    log_info "Code analysis complete. Report saved to: $CODE_ANALYSIS_REPORT_FILE"
}

main "$@"