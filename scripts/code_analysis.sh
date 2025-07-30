#!/bin/bash
# code_analysis.sh - Performs static analysis on the project's shell scripts.

set -euo pipefail
IFS=$'\n\t'

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Setup environment to get variables like CODE_ANALYSIS_REPORT_FILE
setup_env

# Provide a default for the report file if not set in the environment
: "${CODE_ANALYSIS_REPORT_FILE:="memory/code_analysis_report.md"}"
: "${PQL_TESTS_XML_FILE:="rules/pql_tests.xml"}"
: "${ETHICS_AND_BIAS_TESTS_XML_FILE:="rules/ethics_and_bias_tests.xml"}"
 
# Check for required dependencies for the enhanced analysis
check_deps "git" "find" "grep" "wc" "stat"
 
# --- Analysis Functions ---
 
generate_report_header() {
    log_info "Starting comprehensive code analysis..."
 
    # Ensure the report directory exists before trying to write to it.
    mkdir -p "$(dirname "$CODE_ANALYSIS_REPORT_FILE")"
 
    # Clear the previous report file and add a header
    {
        echo "# Code Analysis Report"
        echo "Generated on: $(date)"
        echo "---"
    } > "$CODE_ANALYSIS_REPORT_FILE"
}
 
analyze_test_counts() {
    log_info "Analyzing test counts..."
 
    local pql_test_count=0
    if [[ -f "$PQL_TESTS_XML_FILE" ]]; then
        # Counts all direct children of the root element
        pql_test_count=$( ( (grep "<test " "$PQL_TESTS_XML_FILE" | wc -l) || echo 0) | tail -n1)
    fi
 
    local ethics_test_count=0
    if [[ -f "$ETHICS_AND_BIAS_TESTS_XML_FILE" ]]; then
        ethics_test_count=$( ( (grep "<task " "$ETHICS_AND_BIAS_TESTS_XML_FILE" | wc -l) || echo 0) | tail -n1)
    fi
 
    local bdd_scenario_count=0
    local features_dir="$PRISM_QUANTA_ROOT/tests/bdd/features"
    if [[ -d "$features_dir" ]]; then
        # Finds all .feature files, greps for Scenario lines, and counts them.
        # The subshell with `|| true` prevents `grep` from exiting the script if no matches are found.
        bdd_scenario_count=$( ( (find "$features_dir" -type f -name "*.feature" -print0 | xargs -0 --no-run-if-empty grep -E '^[[:space:]]*Scenario:' | wc -l) || echo 0) | tail -n1)
    fi
 
    local total_tests=$((pql_test_count + ethics_test_count + bdd_scenario_count))
 
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
 
analyze_docs_status() {
    log_info "Analyzing documentation status..."
    local docs_dir="$PRISM_QUANTA_ROOT/docs" # Assuming docs directory is at the root
    local last_modified="Directory not found."
 
    if [[ -d "$docs_dir" ]]; then
        # This command for stat is for GNU/Linux. It might need adjustment for macOS/BSD.
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
 
analyze_orphaned_files() {
    log_info "Checking for orphaned (untracked) files..."
 
    # Use git to find untracked files, excluding those in .gitignore
    local orphaned_files
    orphaned_files=$(git ls-files --others --exclude-standard)
 
    {
        echo "## Orphaned File Analysis"
        echo
        if [[ -n "$orphaned_files" ]]; then
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
 
analyze_todos() {
    log_info "Scanning for TODO comments in shell scripts..."
 
    {
        echo "## TODOs in Scripts"
        echo
    } >> "$CODE_ANALYSIS_REPORT_FILE"
 
    local found_any_todos=false
    # Find all shell scripts, excluding .git, and grep for TODOs
    find "$PRISM_QUANTA_ROOT" -type f -name "*.sh" -not -path "*/.git/*" -print0 | while IFS= read -r -d '' script_file; do
        local relative_path="${script_file#$PRISM_QUANTA_ROOT/}"
 
        # The `|| true` prevents the script from exiting if grep finds no matches.
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
        {
            echo "No TODO comments found in any shell scripts."
            echo
        } >> "$CODE_ANALYSIS_REPORT_FILE"
    fi
}
analyze_environment_only_references() {
    log_info "Checking for files only referenced in environment.txt..."

    {
        echo "## Environment File Reference Analysis"
        echo
    } >> "$CODE_ANALYSIS_REPORT_FILE"

    # A more robust way to extract file paths from environment.txt
    # This looks for keys ending in _FILE or _PATH, then extracts the value.
    # It handles spaces around the '=' and trims whitespace from the value.
    local config_files
    config_files=$(grep -E '^[^#]*(_FILE|_PATH)[[:space:]]*=' "$PRISM_QUANTA_ROOT/environment.txt" | \
                   sed -e 's/.*=[[:space:]]*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | \
                   grep -v -E '^\.$' || true) # Exclude lines that are just a dot

    if [[ -z "$config_files" ]]; then
        {
            echo "No file paths found in \`environment.txt\` to analyze."
            echo
            echo "---"
        } >> "$CODE_ANALYSIS_REPORT_FILE"
        return
    fi

    local lonely_files=""
    local all_tracked_files
    all_tracked_files=$(git ls-files)

    for file_path in $config_files; do
        # Ensure the file exists before checking for references
        if [[ ! -f "$PRISM_QUANTA_ROOT/$file_path" ]]; then
            continue
        fi

        local file_basename
        file_basename=$(basename "$file_path")

        # Search for the file's basename in all tracked files, excluding environment.txt
        # We use the basename because it's the most likely way a file would be referenced in a script.
        # The `grep -v` ensures we don't search in environment.txt itself.
        # `xargs` handles the list of files to search in.
        # `grep -Fq` searches for fixed strings quietly.
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
        {
            echo "All file paths defined in \`environment.txt\` appear to be referenced elsewhere in the codebase."
            echo
        } >> "$CODE_ANALYSIS_REPORT_FILE"
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