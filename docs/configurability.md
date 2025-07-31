# Configurability Enhancement Opportunities

This document outlines how to leverage the project's central configuration system to manage application behavior. The project uses `environment.txt` as the single source of truth for all configuration, which is loaded by the `setup_env` function in `scripts/utils.sh`. This approach ensures that all settings are managed in one place.

---

### 1. Centralize All Configuration in `environment.txt`

*   **Observation:** The project has a robust mechanism for loading configuration from `environment.txt` via the `setup_env` function. However, some configuration values (like script behavior flags or thresholds) may still be hardcoded within individual scripts.
*   **Suggestion:** All configurable values should be moved into `environment.txt`. This provides a single, clear location for all settings, making the system easier to manage. The `scripts/generate_env.sh` script (called by `setup_env`) handles making these values available as environment variables to any script that needs them.

### 3. Make Logging Configurable

*   **Observation:** The logging behavior is static. In a production or testing scenario, one might want to change the log level (e.g., from `INFO` to `DEBUG`) or redirect output without changing the script.
*   **Suggestion:** Add a `LOG_LEVEL` variable to `environment.txt`. The logging functions in `scripts/utils.sh` can then be updated to respect this variable.
    *   **Example in `environment.txt`:**
        ```
        # Logging level can be DEBUG, INFO, WARN, or ERROR
        LOG_LEVEL = INFO
        ```
    *   **Example usage in `scripts/utils.sh`:**
        ```bash
        log_info() {
            # Only log if LOG_LEVEL is DEBUG or INFO
            if [[ "${LOG_LEVEL}" == "DEBUG" || "${LOG_LEVEL}" == "INFO" ]]; then
                echo "[INFO] $1"
            fi
        }
        ```

### 4. Introduce Feature Flags

*   **Observation:** New features (like the intersectional bias check) are enabled for all runs. There is no mechanism for a phased rollout or for quickly disabling a problematic feature.
*   **Suggestion:** Implement a simple feature flag system by adding boolean-like variables to `environment.txt`.
    *   **Example in `environment.txt`:**
        ```
        # Enable or disable the intersectional bias check in the ethics script
        ENABLE_INTERSECTIONAL_CHECK = true
        ```
    *   **Example usage in `scripts/ethics_bias_checker.sh`:**
        ```bash
        # In the detect_bias function, after calling setup_env
        if [[ "${ENABLE_INTERSECTIONAL_CHECK}" == "true" ]]; then
            detect_intersectional_bias "$text" violations
        fi
        ```