#!/bin/bash
# QuantaPorto - Unit Test Runner

set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0

log_pass() {
  echo -e "${GREEN}✔ $1${NC}"
  ((PASS_COUNT++))
}

log_fail() {
  echo -e "${RED}✖ $1${NC}"
  ((FAIL_COUNT++))
}

# 1. Validate rulebook XML
test_rulebook_validation() {
  if [ -f ../rules/rulebook.xml ]; then
    if xmllint --noout ../rules/rulebook.xml 2>/dev/null; then
      log_pass "Rulebook XML is well-formed."
    else
      log_fail "Rulebook XML is malformed!"
    fi
  else
    log_pass "Rulebook XML not found, skipping test."
  fi
}

# 2. Validate PQL schema
test_pql_schema_validation() {
  if xmllint --noout ../pql/pql-schema.xml 2>/dev/null; then
    log_pass "PQL schema is well-formed."
  else
    log_fail "PQL schema is malformed!"
  fi
}

# 3. Template engine test
test_template_output() {
  OUTPUT=$(bash ../scripts/template-parser.sh "test" 2>/dev/null)
  if [[ $OUTPUT == *"Template generated for task"* ]]; then
    log_pass "Template engine output appears correct."
  else
    log_fail "Template engine failed to generate valid output."
  fi
}

# 4. Reflection cycle test (mock)
test_reflection_loop() {
  MOCK_INPUT="Initial response with error"
  MOCK_OUTPUT=$(bash ../scripts/consequence-engine.sh "$MOCK_INPUT" 2>/dev/null)
  if [[ $MOCK_OUTPUT == *"Revising response due to rule violation"* ]]; then
    log_pass "Reflection loop correctly triggered consequence logic."
  else
    log_fail "Reflection logic did not behave as expected."
  fi
}

# 5. Test PQL parser
test_pql_parser() {
  if [ -f ../scripts/parse_pql.sh ]; then
    if bash ../scripts/parse_pql.sh --test 2>/dev/null; then
      log_pass "PQL parser test passed."
    else
      log_fail "PQL parser test failed!"
    fi
  else
    log_fail "PQL parser script not found!"
  fi
}

# 6. Test rule enforcer
test_rule_enforcer() {
  if [ -f ../scripts/rule_enforcer.sh ]; then
    MOCK_INPUT="This is a test input"
    if OUTPUT=$(bash ../scripts/rule_enforcer.sh "$MOCK_INPUT" 2>/dev/null); then
      log_pass "Rule enforcer executed successfully."
    else
      log_fail "Rule enforcer execution failed!"
    fi
  else
    log_fail "Rule enforcer script not found!"
  fi
}

# 7. Test memory review
test_memory_review() {
  if [ -f ../scripts/memory_review.sh ]; then
    if bash ../scripts/memory_review.sh --test 2>/dev/null; then
      log_pass "Memory review test passed."
    else
      log_fail "Memory review test failed!"
    fi
  else
    log_fail "Memory review script not found!"
  fi
}

# 8. Test prompt generation
test_prompt_generation() {
  if [ -f ../scripts/generate_prompt.sh ]; then
    if OUTPUT=$(bash ../scripts/generate_prompt.sh --test 2>/dev/null); then
      log_pass "Prompt generation test passed."
    else
      log_fail "Prompt generation test failed!"
    fi
  else
    log_fail "Prompt generation script not found!"
  fi
}

# 9. Test config files
test_config_files() {
  CONFIG_FILES=("../config/priorities.txt" "../config/rewards.txt" "../config/rules.txt")
  ALL_FOUND=true
  
  for file in "${CONFIG_FILES[@]}"; do
    if [ ! -f "$file" ]; then
      log_fail "Config file not found: $file"
      ALL_FOUND=false
    fi
  done
  
  if $ALL_FOUND; then
    log_pass "All config files exist."
  fi
}

# 10. Test interface compilation
test_interface_compilation() {
  if [ -f "../interface/quantaporto_interface.cpp" ]; then
    if g++ -o /tmp/test_interface ../interface/quantaporto_interface.cpp 2>/dev/null; then
      log_pass "Interface compilation successful."
      rm -f /tmp/test_interface
    else
      log_fail "Interface compilation failed!"
    fi
  else
    log_fail "Interface source file not found!"
  fi
}

# 11. Test validation loop
test_validation_loop() {
  if [ -f ../scripts/validation_loop.sh ]; then
    MOCK_INPUT="Test validation input"
    if OUTPUT=$(bash ../scripts/validation_loop.sh "$MOCK_INPUT" --test 2>/dev/null); then
      log_pass "Validation loop test passed."
    else
      log_fail "Validation loop test failed!"
    fi
  else
    log_fail "Validation loop script not found!"
  fi
}

# 12. Test task manager
test_task_manager() {
  if [ -f ../scripts/task_manager.sh ]; then
    if bash ../scripts/task_manager.sh --list 2>/dev/null; then
      log_pass "Task manager list operation successful."
    else
      log_fail "Task manager list operation failed!"
    fi
  else
    log_fail "Task manager script not found!"
  fi
}

# 13. Test script permissions
test_script_permissions() {
  SCRIPT_DIR="../scripts"
  if [ -d "$SCRIPT_DIR" ]; then
    PERMISSION_ERRORS=0
    for script in "$SCRIPT_DIR"/*.sh; do
      if [ -f "$script" ] && [ ! -x "$script" ]; then
        log_fail "Script not executable: $script"
        ((PERMISSION_ERRORS++))
      fi
    done
    
    if [ $PERMISSION_ERRORS -eq 0 ]; then
      log_pass "All scripts have proper executable permissions."
    fi
  else
    log_fail "Scripts directory not found!"
  fi
}

# 14. Test self chat loop
test_self_chat_loop() {
  if [ -f ../scripts/self_chat_loop.sh ]; then
    if bash ../scripts/self_chat_loop.sh --test 2>/dev/null; then
      log_pass "Self chat loop test passed."
    else
      log_fail "Self chat loop test failed!"
    fi
  else
    log_fail "Self chat loop script not found!"
  fi
}

# 15. Test main executable
test_main_executable() {
  if [ -f ../main ]; then
    if [ -x ../main ]; then
      log_pass "Main executable exists and is executable."
    else
      log_fail "Main executable exists but is not executable!"
    fi
  else
    log_fail "Main executable not found!"
  fi
}

# 16. Test timeout configuration
test_timeout_config() {
  if [ -f ../.timeout ]; then
    TIMEOUT_VALUE=$(cat ../.timeout 2>/dev/null)
    if [[ "$TIMEOUT_VALUE" =~ ^[0-9]+$ ]]; then
      log_pass "Timeout configuration is valid: $TIMEOUT_VALUE seconds."
    else
      log_fail "Timeout configuration is invalid!"
    fi
  else
    log_fail "Timeout configuration file not found!"
  fi
}

# 17. Test project structure integrity
test_project_structure() {
  REQUIRED_DIRS=("../config" "../docs" "../interface" "../memory" "../prompts" "../rules" "../scripts" "../tests")
  STRUCTURE_ERRORS=0
  
  for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
      log_fail "Required directory not found: $dir"
      ((STRUCTURE_ERRORS++))
    fi
  done
  
  if [ $STRUCTURE_ERRORS -eq 0 ]; then
    log_pass "Project structure integrity verified."
  fi
}

# 18. Test README existence and content
test_readme() {
  if [ -f ../README.md ]; then
    if [ -s ../README.md ]; then
      log_pass "README.md exists and has content."
    else
      log_fail "README.md exists but is empty!"
    fi
  else
    log_fail "README.md not found!"
  fi
}

# 19. Test memory files
test_memory_files() {
  MEMORY_DIR="../memory"
  if [ -d "$MEMORY_DIR" ]; then
    FILE_COUNT=$(find "$MEMORY_DIR" -type f | wc -l)
    if [ "$FILE_COUNT" -gt 0 ]; then
      READABLE_COUNT=0
      for file in "$MEMORY_DIR"/*; do
        if [ -r "$file" ]; then
          ((READABLE_COUNT++))
        fi
      done
      
      if [ "$READABLE_COUNT" -eq "$FILE_COUNT" ]; then
        log_pass "All $FILE_COUNT memory files are readable."
      else
        log_fail "Some memory files are not readable!"
      fi
    else
      log_fail "No memory files found in $MEMORY_DIR!"
    fi
  else
    log_fail "Memory directory not found!"
  fi
}

# 20. Test PQL sample files
test_pql_samples() {
  PQL_SAMPLES=("../rules/pql_sample.xml")
  SAMPLE_ERRORS=0
  
  for sample in "${PQL_SAMPLES[@]}"; do
    if [ ! -f "$sample" ]; then
      log_fail "PQL sample file not found: $sample"
      ((SAMPLE_ERRORS++))
    elif ! xmllint --noout "$sample" 2>/dev/null; then
      log_fail "PQL sample file is not valid XML: $sample"
      ((SAMPLE_ERRORS++))
    fi
  done
  
  if [ $SAMPLE_ERRORS -eq 0 ]; then
    log_pass "All PQL sample files exist and are valid XML."
  fi
}

# Run all tests
echo "🔧 Running QuantaPorto Tests..."
test_rulebook_validation
test_pql_schema_validation
test_template_output
test_reflection_loop
test_pql_parser
test_rule_enforcer
test_memory_review
test_prompt_generation
test_config_files
test_interface_compilation
test_validation_loop
test_task_manager
test_script_permissions
test_self_chat_loop
test_main_executable
test_timeout_config
test_project_structure
test_readme
test_memory_files
test_pql_samples

# Summary
echo
echo -e "✅ Passed: ${GREEN}$PASS_COUNT${NC}    ❌ Failed: ${RED}$FAIL_COUNT${NC}"

if [[ $FAIL_COUNT -gt 0 ]]; then
  exit 1
else
  exit 0
fi
