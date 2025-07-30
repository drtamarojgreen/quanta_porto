#!/bin/bash
# enhanced_test_runner.sh - Enhanced BDD Test Runner with Ethics and Bias Testing
# Executes BDD tests for QuantaPorto including comprehensive ethics and bias validation

set -euo pipefail
IFS=$'\n\t'

# Determine project root if not already set, making the script more portable.
if [[ -z "${PRISM_QUANTA_ROOT:-}" ]]; then
    # The script is in tests/bdd, so root is two levels up
    PRISM_QUANTA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." &>/dev/null && pwd)"
    export PRISM_QUANTA_ROOT
fi

# Source utility functions to ensure consistent environment setup
source "$PRISM_QUANTA_ROOT/scripts/utils.sh"

# Configuration
FEATURES_DIR="$PRISM_QUANTA_ROOT/tests/bdd/features"
STEP_DEFINITIONS="$PRISM_QUANTA_ROOT/tests/bdd/step_definitions.sh"
TEST_RESULTS_DIR="$PRISM_QUANTA_ROOT/tests/results"
VERBOSE=false
FILTER=""
PARALLEL=false
MAX_PARALLEL_JOBS=4

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test statistics
TOTAL_SCENARIOS=0
PASSED_SCENARIOS=0
FAILED_SCENARIOS=0
SKIPPED_SCENARIOS=0

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--filter)
                FILTER="$2"
                shift 2
                ;;
            -p|--parallel)
                PARALLEL=true
                shift
                ;;
            -j|--jobs)
                MAX_PARALLEL_JOBS="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  -v, --verbose         Enable verbose output"
                echo "  -f, --filter PATTERN  Run only scenarios matching pattern"
                echo "  -p, --parallel        Run tests in parallel"
                echo "  -j, --jobs N          Maximum parallel jobs (default: 4)"
                echo "  -h, --help            Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done
}

# Initialize test environment
initialize_test_environment() {
    # Load environment variables (like OUTPUT_DIR) from environment.txt
    # This ensures that sourced step definitions can find their dependencies.
    setup_env

    mkdir -p "$TEST_RESULTS_DIR"
    
    # Source step definitions
    if [[ -f "$STEP_DEFINITIONS" ]]; then
        source "$STEP_DEFINITIONS"
    else
        echo -e "${RED}Error: Step definitions file not found: $STEP_DEFINITIONS${NC}" >&2
        exit 1
    fi
    
    # Ensure required tools are available
    check_dependencies
}

# Check for required dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for jq (needed for JSON parsing in ethics tests)
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    # Check for xmlstarlet (needed for XML validation)
    if ! command -v xmlstarlet &> /dev/null; then
        echo -e "${YELLOW}Warning: xmlstarlet not found. XML validation tests may fail.${NC}"
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required dependencies: ${missing_deps[*]}${NC}" >&2
        echo "Please install the missing dependencies and try again." >&2
        exit 1
    fi
}

# Placeholder for scenario-specific setup
setup_test_environment() {
    : # Do nothing for now
}

# Placeholder for scenario-specific cleanup
cleanup_test_environment() {
    : # Do nothing for now
}

# Parse a feature file and extract scenarios
parse_feature_file() {
    local feature_file="$1"
    local current_scenario=""
    local in_scenario=false
    local scenario_steps=()
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        if [[ "$line" =~ ^[[:space:]]*Scenario: ]]; then
            # If we were in a previous scenario, process it
            if [[ "$in_scenario" == "true" && -n "$current_scenario" ]]; then
                process_scenario "$feature_file" "$current_scenario" "${scenario_steps[@]}"
            fi
            
            # Start new scenario
            current_scenario=$(echo "$line" | sed 's/^[[:space:]]*Scenario:[[:space:]]*//')
            in_scenario=true
            scenario_steps=()
            
        elif [[ "$line" =~ ^[[:space:]]*(Given|When|Then|And|But) ]]; then
            if [[ "$in_scenario" == "true" ]]; then
                scenario_steps+=("$line")
            fi
        fi
    done < "$feature_file"
    
    # Process the last scenario
    if [[ "$in_scenario" == "true" && -n "$current_scenario" ]]; then
        process_scenario "$feature_file" "$current_scenario" "${scenario_steps[@]}"
    fi
}

# Process a single scenario
process_scenario() {
    local feature_file="$1"
    local scenario_name="$2"
    shift 2
    local steps=("$@")
    
    # Apply filter if specified
    if [[ -n "$FILTER" && ! "$scenario_name" =~ $FILTER ]]; then
        ((SKIPPED_SCENARIOS++))
        return
    fi
    
    ((TOTAL_SCENARIOS++))
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}Running scenario: $scenario_name${NC}"
    fi
    
    # Set up test environment for this scenario
    setup_test_environment
    
    local scenario_passed=true
    local step_number=1
    
    # Execute each step
    for step in "${steps[@]}"; do
        if ! execute_step "$step" "$step_number"; then
            scenario_passed=false
            break
        fi
        ((step_number++))
    done
    
    # Clean up test environment
    cleanup_test_environment
    
    # Record results
    if [[ "$scenario_passed" == "true" ]]; then
        ((PASSED_SCENARIOS++))
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "${GREEN}✓ Scenario passed: $scenario_name${NC}"
        else
            echo -n "."
        fi
    else
        ((FAILED_SCENARIOS++))
        echo -e "${RED}✗ Scenario failed: $scenario_name${NC}"
        
        # Log failure details
        {
            echo "Feature: $(basename "$feature_file")"
            echo "Scenario: $scenario_name"
            echo "Failed at step $step_number"
            echo "---"
        } >> "$TEST_RESULTS_DIR/failures.log"
    fi
}

# Execute a single step
execute_step() {
    local step_text="$1"
    local step_number="$2"

    if [[ "$VERBOSE" == "true" ]]; then
        echo "  Step $step_number: $step_text"
    fi

    # 1. Generate function name by stripping keywords and arguments in quotes
    local function_name
    function_name="step_$(echo "$step_text" | sed -E 's/^\s*(Given|When|Then|And|But)\s*//' | sed -E 's/\s*".*?"//g' | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' '_' | sed 's/[^a-z0-9_]//g')"

    # 2. Extract arguments from quoted strings
    local args=()
    while IFS= read -r -d '' arg; do
        args+=("$arg")
    done < <(echo "$step_text" | grep -o '".*?"' | tr -d '"' | tr '\n' '\0')

    # 3. Check if function exists
    if ! declare -f "$function_name" > /dev/null; then
        echo -e "${YELLOW}Warning: Step definition not found for: $step_text${NC}"
        echo -e "${YELLOW}Expected function: $function_name${NC}"
        return 1
    fi

    # 4. Execute the step function with its arguments
    if ! "$function_name" "${args[@]}"; then
        echo -e "${RED}Step failed: $step_text${NC}"
        return 1
    fi

    return 0
}

# Run tests in parallel
run_tests_parallel() {
    local feature_files=("$@")
    local pids=()
    local job_count=0
    
    for feature_file in "${feature_files[@]}"; do
        # Wait if we've reached max parallel jobs
        if (( job_count >= MAX_PARALLEL_JOBS )); then
            wait "${pids[0]}"
            pids=("${pids[@]:1}")  # Remove first PID
            ((job_count--))
        fi
        
        # Start new job
        parse_feature_file "$feature_file" &
        pids+=($!)
        ((job_count++))
    done
    
    # Wait for remaining jobs
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
}

# Run tests sequentially
run_tests_sequential() {
    local feature_files=("$@")
    
    for feature_file in "${feature_files[@]}"; do
        echo -e "${BLUE}Processing feature: $(basename "$feature_file")${NC}"
        parse_feature_file "$feature_file"
    done
}

# Generate test report
generate_report() {
    local end_time
    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo
    echo "=========================================="
    echo "BDD Test Results"
    echo "=========================================="
    echo "Total scenarios: $TOTAL_SCENARIOS"
    echo -e "Passed: ${GREEN}$PASSED_SCENARIOS${NC}"
    echo -e "Failed: ${RED}$FAILED_SCENARIOS${NC}"
    echo -e "Skipped: ${YELLOW}$SKIPPED_SCENARIOS${NC}"
    echo "Completed at: $end_time"
    
    # Calculate success rate
    if (( TOTAL_SCENARIOS > 0 )); then
        local success_rate
        success_rate=$(( (PASSED_SCENARIOS * 100) / TOTAL_SCENARIOS ))
        echo "Success rate: ${success_rate}%"
    fi
    
    # Generate detailed report
    {
        echo "BDD Test Report - $end_time"
        echo "=============================="
        echo "Total scenarios: $TOTAL_SCENARIOS"
        echo "Passed: $PASSED_SCENARIOS"
        echo "Failed: $FAILED_SCENARIOS"
        echo "Skipped: $SKIPPED_SCENARIOS"
        if (( TOTAL_SCENARIOS > 0 )); then
            echo "Success rate: $(( (PASSED_SCENARIOS * 100) / TOTAL_SCENARIOS ))%"
        fi
        echo
        
        if [[ -f "$TEST_RESULTS_DIR/failures.log" ]]; then
            echo "Failed Scenarios:"
            echo "=================="
            cat "$TEST_RESULTS_DIR/failures.log"
        fi
    } > "$TEST_RESULTS_DIR/test_report.txt"
    
    echo "Detailed report saved to: $TEST_RESULTS_DIR/test_report.txt"
}

# Main execution function
main() {
    parse_arguments "$@"
    
    echo -e "${BLUE}QuantaPorto Enhanced BDD Test Runner${NC}"
    echo "====================================="
    
    initialize_test_environment
    
    # Find all feature files
    local feature_files=()
    if [[ -d "$FEATURES_DIR" ]]; then
        while IFS= read -r -d '' file; do
            feature_files+=("$file")
        done < <(find "$FEATURES_DIR" -name "*.feature" -print0)
    else
        echo -e "${RED}Error: Features directory not found: $FEATURES_DIR${NC}" >&2
        exit 1
    fi
    
    if [[ ${#feature_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No feature files found in $FEATURES_DIR${NC}"
        exit 0
    fi
    
    echo "Found ${#feature_files[@]} feature file(s)"
    if [[ -n "$FILTER" ]]; then
        echo "Filter: $FILTER"
    fi
    
    local start_time
    start_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo "Started at: $start_time"
    echo
    
    # Run tests
    if [[ "$PARALLEL" == "true" ]]; then
        echo "Running tests in parallel (max jobs: $MAX_PARALLEL_JOBS)"
        run_tests_parallel "${feature_files[@]}"
    else
        run_tests_sequential "${feature_files[@]}"
    fi
    
    # Generate and display report
    generate_report
    
    # Exit with appropriate code
    if (( FAILED_SCENARIOS > 0 )); then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"
