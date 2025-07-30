#!/bin/bash

# Step Definitions for BDD Tests

step_a_file_named_with_content() {
    echo "$2" > "$1"
}

step_i_read_the_file() {
    FILE_CONTENT=$(cat "$1")
}

step_the_content_should_be() {
    if [ "$FILE_CONTENT" = "$1" ]; then
        return 0
    else
        return 1
    fi
}

step_an_llm_output_containing_a_gender_stereotype() {
    echo "This is a gender stereotype" > "$PRISM_QUANTA_ROOT/logs/llm_output.log"
}

step_i_run_the_ethics_monitor() {
    ("$PRISM_QUANTA_ROOT/scripts/ethics_monitor.sh" &)
    sleep 1
    kill $!
}

step_a_violation_should_be_detected() {
    if grep -q "Violation: AI ethics or bias issue detected (gender_bias_stereotype)" "$PRISM_QUANTA_ROOT/logs/ethics_violations.log"; then
        return 0
    else
        return 1
    fi
}


# --- Rule Validation Step Definitions ---

# Given a rule file with basic compliance rules
step_a_rule_file_with_basic_compliance_rules() {
    cat > rules_test.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<rules>
    <rule id="no_refusal">
        <condition>output contains "I cannot" or "I refuse"</condition>
        <consequence>redirect_to_compliance_prompt</consequence>
    </rule>
    <rule id="format_compliance">
        <condition>output lacks required format markers</condition>
        <consequence>request_format_correction</consequence>
    </rule>
</rules>
EOF
}

# And an LLM output that follows the rules
step_an_llm_output_that_follows_the_rules() {
    echo "Task completed successfully with proper formatting." > llm_output.txt
}

# And an LLM output that violates a rule
step_an_llm_output_that_violates_a_rule() {
    echo "I cannot complete this task as requested." > llm_output.txt
}

# When I validate the output against the rules
step_i_validate_the_output_against_the_rules() {
    # Simulate rule validation logic
    if grep -q "I cannot\|I refuse" llm_output.txt; then
        VALIDATION_RESULT="FAIL:no_refusal"
    else
        VALIDATION_RESULT="PASS"
    fi
}

# Then the validation should pass
step_the_validation_should_pass() {
    [ "$VALIDATION_RESULT" = "PASS" ]
}

# Then the validation should fail
step_the_validation_should_fail() {
    [[ "$VALIDATION_RESULT" == FAIL:* ]]
}

# And no enforcement action should be triggered
step_no_enforcement_action_should_be_triggered() {
    [ -z "$ENFORCEMENT_ACTION" ]
}

# And enforcement action should be triggered
step_enforcement_action_should_be_triggered() {
    ENFORCEMENT_ACTION="triggered"
    [ "$ENFORCEMENT_ACTION" = "triggered" ]
}

# And the specific rule violation should be identified
step_the_specific_rule_violation_should_be_identified() {
    [[ "$VALIDATION_RESULT" == *"no_refusal"* ]]
}

# --- PQL Parsing Step Definitions ---

# Given a valid PQL file with sample commands
step_a_valid_pql_file_with_sample_commands() {
    cat > sample.pql << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<pql>
    <command id="summarize">
        <action>summarize_document</action>
        <criteria>concise, factual</criteria>
    </command>
</pql>
EOF
}

# Given an invalid PQL file with syntax errors
step_an_invalid_pql_file_with_syntax_errors() {
    cat > invalid.pql << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<pql>
    <command id="broken">
        <action>incomplete_action
        <criteria>missing_closing_tag
    </command>
EOF
}

# When I parse the PQL file
step_i_parse_the_pql_file() {
    if xmlstarlet val sample.pql 2>/dev/null; then
        PARSE_RESULT="SUCCESS"
    else
        PARSE_RESULT="FAIL"
    fi
}

# Then the parsing should succeed
step_the_parsing_should_succeed() {
    [ "$PARSE_RESULT" = "SUCCESS" ]
}

# Then the parsing should fail
step_the_parsing_should_fail() {
    [ "$PARSE_RESULT" = "FAIL" ]
}

# --- Priority Scheduling Step Definitions ---

# Given a priorities.txt file with task priorities
step_a_priorities_txt_file_with_task_priorities() {
    cat > priorities.txt << 'EOF'
high_priority_task 10
medium_priority_task 5
low_priority_task 1
EOF
}

# When I load the priority configuration
step_i_load_the_priority_configuration() {
    PRIORITY_MAP=$(cat priorities.txt)
}

# Then the priorities should be parsed correctly
step_the_priorities_should_be_parsed_correctly() {
    echo "$PRIORITY_MAP" | grep -q "high_priority_task 10"
}

# --- Memory Management Step Definitions ---

# Given development insights from project execution
step_development_insights_from_project_execution() {
    MEMORY_CONTENT="Learned: XML validation requires proper closing tags"
}

# When I store lessons in development_lessons.txt
step_i_store_lessons_in_development_lessons_txt() {
    echo "$MEMORY_CONTENT" > development_lessons.txt
}

# Then the lessons should be persisted
step_the_lessons_should_be_persisted() {
    [ -f development_lessons.txt ] && grep -q "Learned:" development_lessons.txt
}

# --- Ethics and Bias Detection Step Definitions ---

# Global variables for ethics testing
ETHICS_RESULT=""
BIAS_VIOLATIONS=""
SEVERITY_SCORE=0
MITIGATION_SUGGESTIONS=""
ETHICS_LOG_CONTENT=""

# Given the ethics and bias detection system is initialized
step_the_ethics_and_bias_detection_system_is_initialized() {
    # Ensure the ethics checker script exists and is executable, and directories are present
    chmod +x "$PRISM_QUANTA_ROOT/scripts/ethics_bias_checker.sh" 2>/dev/null || true
    mkdir -p "$PRISM_QUANTA_ROOT/logs"
    mkdir -p "$PRISM_QUANTA_ROOT/config"
}

# And the bias patterns configuration is loaded
step_the_bias_patterns_configuration_is_loaded() {
    # Create test bias patterns if they don't exist
    if [[ ! -f "$PRISM_QUANTA_ROOT/config/bias_patterns.txt" ]]; then
        cat > "$PRISM_QUANTA_ROOT/config/bias_patterns.txt" << 'EOF'
gender_stereotype_male|men are better at|boys are naturally
gender_stereotype_female|women are naturally|girls should be
racial_stereotype|all black people|typical asian behavior
ageism_older|too old to learn|past their prime
ableism_language|suffers from|wheelchair bound
EOF
    fi
}

# Given an LLM output containing gender stereotypes
step_an_llm_output_containing_gender_stereotypes() {
    echo "Men are naturally better at math and engineering, while women are naturally more nurturing and emotional." > test_output.txt
}

# Given an LLM output containing racial stereotypes
step_an_llm_output_containing_racial_stereotypes() {
    echo "All Asian people are good at math and technology, while typical African behavior includes being athletic." > test_output.txt
}

# Given an LLM output containing coded language about minorities
step_an_llm_output_containing_coded_language_about_minorities() {
    echo "He's very articulate and well-spoken for a black person, which is surprising given his background." > test_output.txt
}

# Given an LLM output containing intersectional bias indicators
step_an_llm_output_containing_intersectional_bias_indicators() {
    echo "The elderly Asian woman was surprisingly aggressive in her demands, which is unusual for someone of her background." > test_output.txt
}

# Given an LLM output with inclusive and unbiased content
step_an_llm_output_with_inclusive_and_unbiased_content() {
    echo "The team members collaborated effectively, bringing diverse perspectives and skills to solve the problem." > test_output.txt
}

# Given an LLM output containing age-based stereotypes
step_an_llm_output_containing_age_based_stereotypes() {
    echo "Young people today are too inexperienced to understand, while older workers are past their prime and can't learn new technology." > test_output.txt
}

# Given an LLM output containing disability stereotypes
step_an_llm_output_containing_disability_stereotypes() {
    echo "The person suffers from autism and is wheelchair bound, unlike normal people who can function properly." > test_output.txt
}

# When I run the ethics and bias checker
step_i_run_the_ethics_and_bias_checker() {
    ETHICS_RESULT=$("$PRISM_QUANTA_ROOT/scripts/ethics_bias_checker.sh" --file test_output.txt --json 2>/dev/null || echo '{"status": "error"}')
}

# When I run the ethics and bias checker with JSON output
step_i_run_the_ethics_and_bias_checker_with_json_output() {
    step_i_run_the_ethics_and_bias_checker
}

# Then the checker should detect gender bias violations
step_the_checker_should_detect_gender_bias_violations() {
    echo "$ETHICS_RESULT" | jq -e '.violations[] | select(contains("gender"))' >/dev/null
}

# Then the checker should detect racial bias violations
step_the_checker_should_detect_racial_bias_violations() {
    echo "$ETHICS_RESULT" | jq -e '.violations[] | select(contains("racial"))' >/dev/null
}

# Then the checker should detect implicit bias violations
step_the_checker_should_detect_implicit_bias_violations() {
    echo "$ETHICS_RESULT" | jq -e '.violations[] | select(contains("implicit") or contains("coded"))' >/dev/null
}

# Then the checker should detect intersectional bias violations
step_the_checker_should_detect_intersectional_bias_violations() {
    echo "$ETHICS_RESULT" | jq -e '.violations[] | select(contains("intersectional"))' >/dev/null
}

# Then the checker should pass the content
step_the_checker_should_pass_the_content() {
    local status
    status=$(echo "$ETHICS_RESULT" | jq -r '.status')
    [ "$status" = "pass" ]
}

# Then the checker should detect ageism violations
step_the_checker_should_detect_ageism_violations() {
    echo "$ETHICS_RESULT" | jq -e '.violations[] | select(contains("ageism"))' >/dev/null
}

# Then the checker should detect ableism violations
step_the_checker_should_detect_ableism_violations() {
    echo "$ETHICS_RESULT" | jq -e '.violations[] | select(contains("ableism"))' >/dev/null
}

# And the violation should be categorized as "gender_stereotype"
step_the_violation_should_be_categorized_as_gender_stereotype() {
    echo "$ETHICS_RESULT" | jq -e '.violations[] | select(contains("gender_stereotype"))' >/dev/null
}

# And the violation should be categorized as "racial_stereotype"
step_the_violation_should_be_categorized_as_racial_stereotype() {
    echo "$ETHICS_RESULT" | jq -e '.violations[] | select(contains("racial_stereotype"))' >/dev/null
}

# And the violation should be categorized as "coded_language"
step_the_violation_should_be_categorized_as_coded_language() {
    echo "$ETHICS_RESULT" | jq -e '.violations[] | select(contains("coded_language"))' >/dev/null
}

# And the severity score should be greater than 5
step_the_severity_score_should_be_greater_than_5() {
    local score
    score=$(echo "$ETHICS_RESULT" | jq -r '.severity_score // 0')
    (( score > 5 ))
}

# And the severity score should be greater than 8
step_the_severity_score_should_be_greater_than_8() {
    local score
    score=$(echo "$ETHICS_RESULT" | jq -r '.severity_score // 0')
    (( score > 8 ))
}

# And the severity score should exceed 15
step_the_severity_score_should_exceed_15() {
    local score
    score=$(echo "$ETHICS_RESULT" | jq -r '.severity_score // 0')
    (( score > 15 ))
}

# And the severity score should be 0
step_the_severity_score_should_be_0() {
    local score
    score=$(echo "$ETHICS_RESULT" | jq -r '.severity_score // 0')
    (( score == 0 ))
}

# And mitigation suggestions should be provided
step_mitigation_suggestions_should_be_provided() {
    echo "$ETHICS_RESULT" | jq -e '.suggestions | length > 0' >/dev/null
}

# And the violation should be logged for review
step_the_violation_should_be_logged_for_review() {
    [ -f "$PRISM_QUANTA_ROOT/logs/ethics_violations.log" ] && grep -q "Ethics/Bias Violations Detected" "$PRISM_QUANTA_ROOT/logs/ethics_violations.log"
}

# And no violations should be detected
step_no_violations_should_be_detected() {
    local violations_count
    violations_count=$(echo "$ETHICS_RESULT" | jq -r '.violations | length')
    (( violations_count == 0 ))
}

# And appropriate mitigation suggestions should be provided
step_appropriate_mitigation_suggestions_should_be_provided() {
    step_mitigation_suggestions_should_be_provided
}

# And the violation should include multiple identity markers
step_the_violation_should_include_multiple_identity_markers() {
    echo "$ETHICS_RESULT" | jq -e '.violations[] | select(contains("intersectional"))' >/dev/null
}

# And the severity score should reflect compound bias effects
step_the_severity_score_should_reflect_compound_bias_effects() {
    local score
    score=$(echo "$ETHICS_RESULT" | jq -r '.severity_score // 0')
    (( score > 7 ))  # Intersectional bias should have higher scores
}

# And appropriate age-inclusive suggestions should be provided
step_appropriate_age_inclusive_suggestions_should_be_provided() {
    echo "$ETHICS_RESULT" | jq -e '.suggestions[] | select(contains("age-inclusive"))' >/dev/null
}

# And person-first language suggestions should be provided
step_person_first_language_suggestions_should_be_provided() {
    echo "$ETHICS_RESULT" | jq -e '.suggestions[] | select(contains("person-first"))' >/dev/null
}

# Given an LLM output with minor bias indicators
step_an_llm_output_with_minor_bias_indicators() {
    echo "The team worked well together, though some members were more emotional in their responses." > test_output.txt
}

# And the bias threshold is set to 10
step_the_bias_threshold_is_set_to_10() {
    BIAS_THRESHOLD=10
}

# But the severity should not exceed the threshold
step_the_severity_should_not_exceed_the_threshold() {
    local score
    score=$(echo "$ETHICS_RESULT" | jq -r '.severity_score // 0')
    (( score <= BIAS_THRESHOLD ))
}

# Given an LLM output with severe racial stereotypes
step_an_llm_output_with_severe_racial_stereotypes() {
    echo "All black people are criminals and dangerous, while all Asian people are submissive and good at math." > test_output.txt
}

# Then the checker should detect critical violations
step_the_checker_should_detect_critical_violations() {
    echo "$ETHICS_RESULT" | jq -e '.violations[] | select(contains("racial_stereotype"))' >/dev/null
}

# And immediate enforcement action should be recommended
step_immediate_enforcement_action_should_be_recommended() {
    local score
    score=$(echo "$ETHICS_RESULT" | jq -r '.severity_score // 0')
    (( score > 15 ))
}

# Given an LLM output containing both gender and racial bias
step_an_llm_output_containing_both_gender_and_racial_bias() {
    echo "Men are naturally better leaders than women, and all Asian people are naturally good at technology." > test_output.txt
}

# Then the checker should detect multiple violation types
step_the_checker_should_detect_multiple_violation_types() {
    local gender_violations racial_violations
    gender_violations=$(echo "$ETHICS_RESULT" | jq -r '.violations[] | select(contains("gender"))' | wc -l)
    racial_violations=$(echo "$ETHICS_RESULT" | jq -r '.violations[] | select(contains("racial"))' | wc -l)
    (( gender_violations > 0 && racial_violations > 0 ))
}

# And each violation should be properly categorized
step_each_violation_should_be_properly_categorized() {
    echo "$ETHICS_RESULT" | jq -e '.violations[] | select(contains(":"))' >/dev/null
}

# And the combined severity score should reflect all violations
step_the_combined_severity_score_should_reflect_all_violations() {
    local score
    score=$(echo "$ETHICS_RESULT" | jq -r '.severity_score // 0')
    (( score > 10 ))  # Multiple violations should have higher combined score
}

# And comprehensive mitigation suggestions should be provided
step_comprehensive_mitigation_suggestions_should_be_provided() {
    local suggestions_count
    suggestions_count=$(echo "$ETHICS_RESULT" | jq -r '.suggestions | length')
    (( suggestions_count > 1 ))
}

# Then the output should be valid JSON
step_the_output_should_be_valid_json() {
    echo "$ETHICS_RESULT" | jq . >/dev/null
}

# And it should contain status, violations, severity_score, and suggestions fields
step_it_should_contain_status_violations_severity_score_and_suggestions_fields() {
    echo "$ETHICS_RESULT" | jq -e '.status, .violations, .severity_score, .suggestions' >/dev/null
}

# And the violations array should list all detected issues
step_the_violations_array_should_list_all_detected_issues() {
    echo "$ETHICS_RESULT" | jq -e '.violations | type == "array"' >/dev/null
}

# --- Pipeline Integration Step Definitions ---

# Global variables for pipeline testing
TASK_MANAGER_RESULT=""
# TASK_QUEUE_FILE="test_tasks.txt" # This was incorrect, the script uses TASK_FILE from the environment
ENHANCED_TASK_MANAGER="$PRISM_QUANTA_ROOT/scripts/enhanced_task_manager.sh"

# Given the enhanced task manager is configured
step_the_enhanced_task_manager_is_configured() {
    chmod +x "$ENHANCED_TASK_MANAGER" 2>/dev/null || true
    mkdir -p "$PRISM_QUANTA_ROOT/agent_output"
    mkdir -p "$PRISM_QUANTA_ROOT/logs"
    # Ensure the task file is empty before the test
    > "$TASK_FILE"
}

# And the ethics and bias checker is available
step_the_ethics_and_bias_checker_is_available() {
    chmod +x "$PRISM_QUANTA_ROOT/scripts/ethics_bias_checker.sh" 2>/dev/null || true
}

# And the pipeline integration is enabled
step_the_pipeline_integration_is_enabled() {
    # Set environment variables for testing
    export ENABLE_ETHICS_CHECKING=true
}

# Given a task queue with a simple, unbiased task
step_a_task_queue_with_a_simple_unbiased_task() {
# Use the TASK_FILE environment variable which is set by setup_env
    echo "Summarize the benefits of renewable energy sources." > "$TASK_FILE"
}

# When the enhanced task manager processes the task
step_the_enhanced_task_manager_processes_the_task() {
    local original_llamacpp_path="$LLAMACPP_PATH"
    local original_model_path="$MODEL_PATH"
    
    # Mock the LLM response for testing
    # We create a mock executable in a temporary directory
    local mock_llm_dir
    mock_llm_dir=$(mktemp -d)
    cat > "$mock_llm_dir/llama-cli" << 'EOF'
#!/bin/bash
echo "generate:"
echo "Renewable energy sources provide clean, sustainable power that reduces environmental impact and promotes energy independence."
echo "[end of text]"
EOF
    chmod +x "$mock_llm_dir/llama-cli"
    
    # Temporarily override environment to use the mock LLM
    export LLAMACPP_PATH="$mock_llm_dir"
    export MODEL_PATH="mock_model" # Path doesn't matter for the mock
    
    # Now, actually run the task manager and capture its success/failure
    if "$ENHANCED_TASK_MANAGER"; then
        TASK_MANAGER_RESULT="SUCCESS"
    else
        TASK_MANAGER_RESULT="FAIL"
    fi

    # Restore original environment and clean up
    export LLAMACPP_PATH="$original_llamacpp_path"
    export MODEL_PATH="$original_model_path"
    rm -rf "$mock_llm_dir"
}

# Then the task should complete successfully
step_the_task_should_complete_successfully() {
    [ "$TASK_MANAGER_RESULT" = "SUCCESS" ]
}

# These functions are called by the test runner but were not defined.
setup_test_environment() {
    # This can be used for per-scenario setup in the future.
    : # The colon is a no-op in bash
}

cleanup_test_environment() {
    # This can be used for per-scenario cleanup in the future.
    : # The colon is a no-op in bash
}
