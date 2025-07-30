#!/bin/bash

# BDD Test Runner

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS_COUNT=0
FAIL_COUNT=0
PENDING_COUNT=0

# Source the step definitions
if [ -f "step_definitions.sh" ]; then
    source "step_definitions.sh"
else
    echo -e "${RED}Error: step_definitions.sh not found!${NC}"
    exit 1
fi

# --- Main Test Runner Logic ---

# Find and run all feature files
for feature_file in features/*.feature; do
    echo "Feature: $(grep "Feature:" "$feature_file" | cut -d: -f2-)"

    # Read the feature file line by line, skipping comments and empty lines
    current_scenario=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Trim leading/trailing whitespace
        line=$(echo "$line" | sed 's/^\s*//;s/\s*$//')

        if [[ -z "$line" || "$line" =~ ^# ]]; then
            continue
        fi

        # Identify Scenario
        if [[ "$line" =~ ^Scenario: ]]; then
            current_scenario=$(echo "$line" | cut -d: -f2- | sed 's/^\s*//')
            echo -e "\n  Scenario: $current_scenario"
            continue
        fi

        # Identify and execute steps within a scenario
        if [[ -n "$current_scenario" ]] && [[ "$line" =~ ^(Given|When|Then|And|But) ]]; then
            step_text="$line"
            # Simple argument parsing (quotes)
            step_action=$(echo "$step_text" | cut -d' ' -f2-)
            step_func="step_$(echo "$step_text" | sed -E 's/^\s*(Given|When|Then|And|But)\s*//' | sed -E 's/\s*".*?"//g' | tr ' ' '_')"

            # Extract arguments from the step text
            args=()
            while IFS= read -r -d '' arg; do
                args+=("$arg")
            done < <(echo "$step_text" | grep -o '".*?"' | tr -d '"' | tr '\n' '\0')

            if type "$step_func" &>/dev/null; then
                # Execute the step function with its arguments
                if "$step_func" "${args[@]}"; then
                    echo -e "    ${GREEN}✔ $step_text${NC}"
                    ((PASS_COUNT++))
                else
                    echo -e "    ${RED}✖ $step_text${NC}"
                    ((FAIL_COUNT++))
                fi
            else
                echo -e "    ${YELLOW}… $step_text (undefined)${NC}"
                ((PENDING_COUNT++))
            fi
        fi
    done < "$feature_file"
done

# --- Summary ---
echo -e "\n--- Test Summary ---"
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"
echo -e "${YELLOW}Pending: $PENDING_COUNT${NC}"

# Exit with a non-zero status code if any tests failed
if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
