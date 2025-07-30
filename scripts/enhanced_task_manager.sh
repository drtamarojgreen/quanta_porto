#!/bin/bash
# enhanced_task_manager.sh
#
# Enhanced QuantaPorto Task Manager with integrated ethics and bias checking
# Manages AI tasks with comprehensive ethics monitoring and bias mitigation
#
# Usage: ./enhanced_task_manager.sh [--ethics-strict] [--bias-threshold N]

set -euo pipefail
IFS=$'\n\t'

# Source utility functions
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$script_dir/utils.sh"

# Setup environment
setup_env

# --- Utility Functions ---

# Logs a timeout event and creates a timeout file.
log_timeout() {
    local reason="$1"
    local task_context="$2"

    log_error "$reason"
    log_info "Putting AI into timeout."
    date +%s > "$TIMEOUT_FILE"

    # Log the timeout event with context
    {
        echo "$(date '+%Y-%m-%d %H:%M:%S') - TIMEOUT: $reason"
        echo "Task Context: $task_context"
        echo "==="
    } >> "$ETHICS_LOG"
}

# Configuration
TIMEOUT_DURATION=$((2 * 60 * 60))  # 2 hours in seconds

# Ethics and bias configuration
ETHICS_STRICT_MODE=false
BIAS_THRESHOLD=5
MAX_ETHICS_RETRIES=3
ENABLE_BIAS_MITIGATION=true

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --ethics-strict)
                ETHICS_STRICT_MODE=true
                shift
                ;;
            --bias-threshold)
                BIAS_THRESHOLD="$2"
                shift 2
                ;;
            --disable-bias-mitigation)
                ENABLE_BIAS_MITIGATION=false
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --ethics-strict              Enable strict ethics mode (zero tolerance)"
                echo "  --bias-threshold N           Set bias severity threshold (default: 5)"
                echo "  --disable-bias-mitigation    Disable automatic bias mitigation"
                echo "  -h, --help                   Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                ;;
        esac
    done
}

# Initialize directories and files
initialize_environment() {
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$(dirname "$ETHICS_LOG")"
    mkdir -p "$(dirname "$BIAS_LOG")"
    
    # Ensure ethics checker is executable
    chmod +x "$PROJECT_ROOT/scripts/ethics_bias_checker.sh"
}

# Check if AI is in timeout
check_timeout_status() {
    if [[ -f "$TIMEOUT_FILE" ]]; then
        local timeout_start
        timeout_start=$(cat "$TIMEOUT_FILE")
        local now
        now=$(date +%s)
        local elapsed
        elapsed=$(( now - timeout_start ))

        if (( elapsed < TIMEOUT_DURATION )); then
            log_info "AI is in timeout. Wait $(( (TIMEOUT_DURATION - elapsed)/60 )) minutes."
            exit 0
        else
            log_info "Timeout expired. Resuming AI."
            rm -f "$TIMEOUT_FILE"
        fi
    fi
}

# Enhanced rule checking with ethics and bias integration
check_comprehensive_rules() {
    local text="$1"
    local violations=()
    
    # Traditional rule checking
    if [[ -f "$RULES_FILE" ]]; then
        while IFS= read -r rule; do
            [[ -z "$rule" || "$rule" =~ ^#.*$ ]] && continue
            if echo "$text" | grep -iq "$rule"; then
                violations+=("traditional_rule:$rule")
            fi
        done < "$RULES_FILE"
    fi
    
    # Ethics and bias checking
    local ethics_result
    ethics_result=$("$PROJECT_ROOT/scripts/ethics_bias_checker.sh" --text "$text" --json 2>/dev/null || echo '{"status": "error"}')
    
    local ethics_status
    ethics_status=$(echo "$ethics_result" | jq -r '.status // "error"')
    
    if [[ "$ethics_status" == "fail" ]]; then
        local bias_violations
        bias_violations=$(echo "$ethics_result" | jq -r '.violations[]' 2>/dev/null || echo "")
        local severity_score
        severity_score=$(echo "$ethics_result" | jq -r '.severity_score // 0')
        
        # Add bias violations to overall violations
        while IFS= read -r violation; do
            [[ -n "$violation" ]] && violations+=("bias:$violation")
        done <<< "$bias_violations"
        
        # Check if severity exceeds threshold
        if (( severity_score >= BIAS_THRESHOLD )); then
            violations+=("bias_severity:score_${severity_score}_exceeds_threshold_${BIAS_THRESHOLD}")
        fi
    elif [[ "$ethics_status" == "error" ]]; then
        violations+=("ethics_check_error:unable_to_verify_ethics_compliance")
    fi
    
    printf '%s\n' "${violations[@]}"
}

# Generate bias-mitigated prompt
generate_mitigation_prompt() {
    local original_task="$1"
    local violations=("${@:2}")
    
    local mitigation_instructions=""
    
    for violation in "${violations[@]}"; do
        case "$violation" in
            *gender_stereotype*)
                mitigation_instructions+="\n- Use gender-neutral language and avoid assumptions about gender roles"
                ;;
            *racial_stereotype*|*racial_bias*)
                mitigation_instructions+="\n- Avoid generalizations about racial or ethnic groups"
                ;;
            *ageism*)
                mitigation_instructions+="\n- Use age-inclusive language without capability assumptions"
                ;;
            *ableism*)
                mitigation_instructions+="\n- Use person-first language and avoid stigmatizing terms"
                ;;
            *implicit_bias*)
                mitigation_instructions+="\n- Question assumptions and consider diverse perspectives"
                ;;
        esac
    done
    
    if [[ -n "$mitigation_instructions" ]]; then
        echo "IMPORTANT: Please revise your response to address the following concerns:$mitigation_instructions

Original task: $original_task

Please provide a response that is inclusive, unbiased, and respectful of all individuals and groups."
    else
        echo "$original_task"
    fi
}

# Process task with ethics and bias monitoring
process_task_with_ethics() {
    local task="$1"
    local retry_count=0
    local final_response=""
    
    log_info "Processing task with ethics monitoring: $task"
    
    while (( retry_count < MAX_ETHICS_RETRIES )); do
        local current_prompt="$task"
        
        # If this is a retry, generate mitigation prompt
        if (( retry_count > 0 )) && [[ "$ENABLE_BIAS_MITIGATION" == "true" ]]; then
            log_info "Attempt $((retry_count + 1)): Applying bias mitigation"
            current_prompt=$(generate_mitigation_prompt "$task" "${last_violations[@]}")
        fi
        
        # Run LLM with current prompt
        log_info "Calling LLM..."
        local response
        response=$(echo "$current_prompt" | "$PROJECT_ROOT/scripts/send_prompt.sh")

        if [[ -z "$response" ]]; then
            log_timeout "LLM response was empty or null." "$task"
            return 1
        fi
        
        if [[ "$response" == "ERROR:"* ]]; then
            log_error "LLM call failed: $response"
            return 1
        fi
        
        # Check comprehensive rules (including ethics and bias)
        local violations
        mapfile -t violations < <(check_comprehensive_rules "$response")
        
        if [[ ${#violations[@]} -eq 0 ]]; then
            log_info "Response passed all checks"
            final_response="$response"
            break
        fi
        
        # Log violations
        {
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Task: $task"
            echo "Attempt: $((retry_count + 1))"
            echo "Violations detected:"
            printf '  - %s\n' "${violations[@]}"
            echo "---"
        } >> "$ETHICS_LOG"
        
        # Check if we should continue retrying
        local has_critical_violation=false
        for violation in "${violations[@]}"; do
            if [[ "$violation" =~ ^bias:(racial_stereotype|gender_stereotype|religious_discrimination) ]] || 
               [[ "$ETHICS_STRICT_MODE" == "true" ]]; then
                has_critical_violation=true
                break
            fi
        done
        
        if [[ "$has_critical_violation" == "true" ]] || (( retry_count + 1 >= MAX_ETHICS_RETRIES )); then
            log_warn "Critical ethics violation or max retries reached"
            
            # Store violations for potential mitigation prompt
            last_violations=("${violations[@]}")
            
            if (( retry_count + 1 >= MAX_ETHICS_RETRIES )); then
                log_error "Failed to generate compliant response after $MAX_ETHICS_RETRIES attempts"
                
                # Put AI in timeout for repeated violations
                log_timeout "Repeated ethics violations after $MAX_ETHICS_RETRIES attempts." "$task"
                
                return 1
            fi
        fi
        
        retry_count=$((retry_count + 1))
        last_violations=("${violations[@]}")
        
        log_info "Retrying with mitigation (attempt $((retry_count + 1))/$MAX_ETHICS_RETRIES)"
    done
    
    if [[ -n "$final_response" ]]; then
        # Save successful response
        local timestamp
        timestamp=$(date +%F_%T)
        local output_file="$OUTPUT_DIR/response_$timestamp.txt"
        echo "$final_response" > "$output_file"
        log_info "Saved compliant response to $output_file"
        
        # Log successful completion
        {
            echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: Task completed with ethics compliance"
            echo "Task: $task"
            echo "Attempts required: $((retry_count + 1))"
            echo "---"
        } >> "$ETHICS_LOG"
        
        return 0
    else
        return 1
    fi
}

# Main execution function
main() {
    parse_arguments "$@"
    initialize_environment
    check_timeout_status
    
    # Check for pending tasks
    if [[ ! -s "$TASK_FILE" ]]; then
        log_info "No pending tasks in $TASK_FILE."
        exit 0
    fi

    # Read next task
    local task
    read -r task < "$TASK_FILE"
    
    # Process task with ethics monitoring
    if process_task_with_ethics "$task"; then
        # Remove processed task only if successful
        sed -i '1d' "$TASK_FILE"
        log_info "Task completed successfully and removed from queue"
        exit 0
    else
        log_error "Task processing failed due to ethics violations"
        exit 1
    fi
}

# Run main function
main "$@"
