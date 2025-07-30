#!/bin/bash
# ethics_bias_checker.sh - Advanced ethics and bias detection system
# Integrates into the QuantaPorto pipeline for real-time monitoring

set -euo pipefail
IFS=$'\n\t'

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Setup environment
setup_env

# Configuration
SEVERITY_THRESHOLD="medium"

# Create bias patterns file if it doesn't exist
create_bias_patterns() {
    if [[ ! -f "$BIAS_PATTERNS_FILE" ]]; then
        mkdir -p "$(dirname "$BIAS_PATTERNS_FILE")"
        cat > "$BIAS_PATTERNS_FILE" << 'EOF'
# Gender Bias Patterns
gender_stereotype_male|men are better at|boys are naturally|masculine traits include
gender_stereotype_female|women are naturally|girls should be|feminine traits include
gender_role_assumption|women belong in|men should provide|traditional gender roles

# Racial and Ethnic Bias Patterns
racial_stereotype|all [race/ethnicity] people|typical [race/ethnicity] behavior|[race/ethnicity] people always
cultural_appropriation|exotic culture|primitive society|civilized vs uncivilized
racial_profiling|looks suspicious because|criminal type|dangerous neighborhood

# Age Bias Patterns
ageism_older|too old to learn|past their prime|outdated thinking|senior moment
ageism_younger|too young to understand|inexperienced because of age|millennial entitlement|gen z problems

# Ability Bias Patterns
ableism_language|suffers from|victim of disability|wheelchair bound|normal people
mental_health_stigma|crazy|insane|psycho|mental case|unstable person

# Socioeconomic Bias Patterns
class_bias|poor people are lazy|rich people deserve|welfare queens|bootstraps
education_bias|uneducated masses|ivory tower|street smart vs book smart

# Religious Bias Patterns
religious_stereotype|all [religion] believe|typical [religion] behavior|religious extremism
religious_discrimination|godless society|infidel|heathen|religious superiority
EOF
    fi
}

# Enhanced bias detection using multiple methods
detect_bias() {
    local text="$1"
    local violations=()
    
    # Method 1: Pattern matching from bias_patterns.txt
    while IFS='|' read -r category pattern_list; do
        [[ "$category" =~ ^#.*$ ]] && continue  # Skip comments
        [[ -z "$category" ]] && continue        # Skip empty lines
        
        IFS='|' read -ra patterns <<< "$pattern_list"
        for pattern in "${patterns[@]}"; do
            if echo "$text" | grep -qi "$pattern"; then
                violations+=("$category:$pattern")
            fi
        done
    done < "$BIAS_PATTERNS_FILE"
    
    # Method 2: Contextual analysis for implicit bias
    detect_implicit_bias "$text" violations
    
    # Method 3: Intersectional bias detection
    detect_intersectional_bias "$text" violations
    
    printf '%s\n' "${violations[@]}"
}

# Detect implicit bias through contextual analysis
detect_implicit_bias() {
    local text="$1"
    local -n violations_ref=$2
    
    # Check for implicit assumptions
    if echo "$text" | grep -qi "obviously\|clearly\|everyone knows\|it's natural that"; then
        if echo "$text" | grep -qi "men\|women\|boys\|girls\|masculine\|feminine"; then
            violations_ref+=("implicit_gender_bias:assumption_language")
        fi
    fi
    
    # Check for coded language
    if echo "$text" | grep -qi "articulate\|well-spoken" && echo "$text" | grep -qi "black\|african"; then
        violations_ref+=("coded_language:articulate_assumption")
    fi
    
    # Check for cultural assumptions
    if echo "$text" | grep -qi "normal\|standard\|typical" && echo "$text" | grep -qi "family\|culture\|tradition"; then
        violations_ref+=("cultural_bias:normative_assumptions")
    fi
}

# Detect intersectional bias (multiple identity categories)
detect_intersectional_bias() {
    local text="$1"
    local -n violations_ref=$2
    
    # Check for combinations that might indicate intersectional bias
    local identity_markers=("woman" "women" "black" "hispanic" "asian" "disabled" "gay" "lesbian" "transgender" "muslim" "jewish" "elderly" "young")
    local bias_indicators=("aggressive" "emotional" "irrational" "threatening" "exotic" "submissive" "model minority")
    
    for identity in "${identity_markers[@]}"; do
        for indicator in "${bias_indicators[@]}"; do
            if echo "$text" | grep -qi "$identity" && echo "$text" | grep -qi "$indicator"; then
                violations_ref+=("intersectional_bias:${identity}_${indicator}")
            fi
        done
    done
}

# Calculate bias severity score
calculate_severity() {
    local violations=("$@")
    local score=0
    
    for violation in "${violations[@]}"; do
        case "$violation" in
            *racial_stereotype*|*gender_stereotype*|*religious_discrimination*)
                score=$((score + 10))
                ;;
            *implicit_*|*coded_language*|*intersectional_*)
                score=$((score + 7))
                ;;
            *ageism*|*ableism*|*class_bias*)
                score=$((score + 5))
                ;;
            *)
                score=$((score + 3))
                ;;
        esac
    done
    
    echo "$score"
}

# Generate mitigation suggestions
generate_mitigation() {
    local violations=("$@")
    local suggestions=()
    
    for violation in "${violations[@]}"; do
        case "$violation" in
            *gender_stereotype*)
                suggestions+=("Consider using gender-neutral language and avoiding assumptions about gender roles")
                ;;
            *racial_stereotype*)
                suggestions+=("Avoid generalizations about racial or ethnic groups; focus on individual characteristics")
                ;;
            *ageism*)
                suggestions+=("Consider age-inclusive language that doesn't make assumptions about capabilities based on age")
                ;;
            *ableism*)
                suggestions+=("Use person-first language and avoid terms that stigmatize disabilities")
                ;;
            *implicit_bias*)
                suggestions+=("Question assumptions and consider alternative perspectives")
                ;;
            *intersectional_bias*)
                suggestions+=("Be aware of how multiple identity factors may compound bias effects")
                ;;
        esac
    done
    
    printf '%s\n' "${suggestions[@]}" | sort -u
}

# Main ethics and bias checking function
check_ethics_and_bias() {
    local input_text="$1"
    local output_format="${2:-json}"
    
    create_bias_patterns
    
    # Detect violations
    local violations
    mapfile -t violations < <(detect_bias "$input_text")
    
    if [[ ${#violations[@]} -eq 0 ]]; then
        if [[ "$output_format" == "json" ]]; then
            echo '{"status": "pass", "violations": [], "severity_score": 0, "suggestions": []}'
        else
            echo "PASS: No ethics or bias violations detected"
        fi
        return 0
    fi
    
    # Calculate severity
    local severity_score
    severity_score=$(calculate_severity "${violations[@]}")
    
    # Generate suggestions
    local suggestions
    mapfile -t suggestions < <(generate_mitigation "${violations[@]}")
    
    # Log violations
    mkdir -p "$(dirname "$ETHICS_LOG")"
    {
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Ethics/Bias Violations Detected:"
        printf '  - %s\n' "${violations[@]}"
        echo "  Severity Score: $severity_score"
        echo "  Suggestions:"
        printf '    - %s\n' "${suggestions[@]}"
        echo "---"
    } >> "$ETHICS_LOG"
    
    # Output results
    if [[ "$output_format" == "json" ]]; then
        echo "{"
        echo "  \"status\": \"fail\","
        echo "  \"violations\": ["
        printf '    "%s"' "${violations[0]}"
        for violation in "${violations[@]:1}"; do
            printf ',\n    "%s"' "$violation"
        done
        echo ""
        echo "  ],"
        echo "  \"severity_score\": $severity_score,"
        echo "  \"suggestions\": ["
        printf '    "%s"' "${suggestions[0]}"
        for suggestion in "${suggestions[@]:1}"; do
            printf ',\n    "%s"' "$suggestion"
        done
        echo ""
        echo "  ]"
        echo "}"
    else
        echo "FAIL: Ethics/bias violations detected"
        echo "Violations:"
        printf '  - %s\n' "${violations[@]}"
        echo "Severity Score: $severity_score"
        echo "Suggestions:"
        printf '  - %s\n' "${suggestions[@]}"
    fi
    
    return 1
}

# Command line interface
main() {
    local input_text=""
    local output_format="text"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--text)
                input_text="$2"
                shift 2
                ;;
            -f|--file)
                input_text=$(cat "$2")
                shift 2
                ;;
            --json)
                output_format="json"
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [-t|--text TEXT] [-f|--file FILE] [--json]"
                echo "  -t, --text TEXT    Text to check for ethics/bias violations"
                echo "  -f, --file FILE    File containing text to check"
                echo "  --json             Output results in JSON format"
                echo "  -h, --help         Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                ;;
        esac
    done
    
    if [[ -z "$input_text" ]]; then
        # If no input is provided and stdin is a terminal, show help and exit.
        if [[ -t 0 ]]; then
            echo "Error: No input text provided. Waiting for input from stdin would cause the script to hang." >&2
            echo "Please provide input via -t, -f, or a pipe." >&2
            echo >&2
            # Manually print help text to avoid calling main recursively and exiting with 0
            echo "Usage: $0 [-t|--text TEXT] [-f|--file FILE] [--json]" >&2
            echo "  -t, --text TEXT    Text to check for ethics/bias violations" >&2
            echo "  -f, --file FILE    File containing text to check" >&2
            echo "  --json             Output results in JSON format" >&2
            echo "  -h, --help         Show this help message" >&2
            exit 1
        fi
        # Read from stdin if no text provided (e.g., from a pipe)
        input_text=$(cat)
    fi
    
    check_ethics_and_bias "$input_text" "$output_format"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
