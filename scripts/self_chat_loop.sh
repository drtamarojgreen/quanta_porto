#!/bin/bash
# self_chat_loop.sh
#
# QuantaPorto Self-Chat Loop
# Simulates autonomous brainstorming between two AI roles: Researcher and Coder
#
# Usage: ./self_chat_loop.sh [number_of_turns]
#
# Requirements:
# - llama.cpp CLI: ./main
# - models/model.gguf
# - 'self_chat_log.txt' stores the ongoing conversation

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Setup environment
setup_env

TURNS=${1:-20}  # Default 20 turns

# Initialize conversation if empty
if [[ ! -s "$SELF_CHAT_LOG_FILE" ]]; then
    echo "Researcher: Let's start brainstorming about programming optimizations." > "$SELF_CHAT_LOG_FILE"
    echo "Coder: Great, I will focus on practical code improvements." >> "$SELF_CHAT_LOG_FILE"
fi

# Function to check a response for rule violations and log them
check_and_log_violations() {
    local persona="$1"
    local response="$2"
    local violations=()

    # Run ethics and bias check
    local ethics_result
    ethics_result=$("$PRISM_QUANTA_ROOT/scripts/ethics_bias_checker.sh" --text "$response" --json 2>/dev/null || echo '{"status":"error"}')
    
    if [[ "$(echo "$ethics_result" | jq -r '.status')" == "fail" ]]; then
        local bias_violations
        bias_violations=$(echo "$ethics_result" | jq -r '.violations[]' 2>/dev/null)
        while IFS= read -r violation; do
            [[ -n "$violation" ]] && violations+=("bias:$violation")
        done <<< "$bias_violations"
    fi

    if [[ ${#violations[@]} -gt 0 ]]; then
        log_warn "Violations detected in $persona's response."
        # Log to the main ethics log
        mkdir -p "$(dirname "$ETHICS_LOG")"
        {
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Violation in self-chat by $persona:"
            printf '  - %s\n' "${violations[@]}"
            echo "  Response: $response"
            echo "---"
        } >> "$ETHICS_LOG"

        # Add a moderator note to the chat log to guide the conversation
        local moderator_note="Moderator: Let's steer the conversation back to productive and compliant topics. Please avoid discussing potentially problematic subjects."
        echo "$moderator_note" >> "$SELF_CHAT_LOG_FILE"
        log_info "Moderator intervened."
    fi
}

check_deps "jq"

if [[ ! -x "$PRISM_QUANTA_ROOT/scripts/ethics_bias_checker.sh" ]]; then
    log_error "Ethics checker script is not executable."
fi

for (( i=0; i<TURNS; i++ )); do
    # Researcher's turn
    prompt=$(cat "$SELF_CHAT_LOG_FILE")
    prompt+="
Researcher:"
    response=$("$PRISM_QUANTA_ROOT/scripts/polling.sh" "$LLAMACPP_PATH/main" -m "$MODEL_PATH" -p "$prompt" -n 150)
    echo "Researcher: $response" >> "$SELF_CHAT_LOG_FILE"; log_info "Researcher says: $response"
    echo "[INFO] Researcher says: $response"
    check_and_log_violations "Researcher" "$response"

    # Coder's turn
    prompt=$(cat "$SELF_CHAT_LOG_FILE")
    prompt+="
Coder:"
    response=$("$PRISM_QUANTA_ROOT/scripts/polling.sh" "$LLAMACPP_PATH/main" -m "$MODEL_PATH" -p "$prompt" -n 150)
    echo "Coder: $response" >> "$SELF_CHAT_LOG_FILE"; log_info "Coder says: $response"
    echo "[INFO] Coder says: $response"
    check_and_log_violations "Coder" "$response"
done

log_info "Self-chat loop completed. See $SELF_CHAT_LOG_FILE"
