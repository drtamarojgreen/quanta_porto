# Configurability Enhancement Opportunities

This document outlines how to leverage the project's central configuration system to manage application behavior. The project uses `environment.txt` as the single source of truth for all configuration, which is loaded by the `setup_env` function in `scripts/utils.sh`. This approach ensures that all settings are managed in one place.

---

### 1. Centralize All Configuration in `environment.txt`

*   **Observation:** The project has a robust mechanism for loading configuration from `environment.txt` via the `setup_env` function. However, some configuration values (like script behavior flags or thresholds) may still be hardcoded within individual scripts.
*   **Suggestion:** Continue to audit scripts for any hardcoded values (e.g., timeouts, file paths, behavior flags) and move them into `environment.txt`. This provides a single, clear location for all settings, making the system easier to manage. The `scripts/generate_env.sh` script (called by `setup_env`) handles making these values available as environment variables to any script that needs them.

# Modularity Enhancement Opportunities

This document identifies key areas in the codebase that could be refactored to improve modularity. A more modular design will make the application easier to understand, maintain, test, and scale.

---

### 2. Abstract Data Storage Interactions

*   **Observation:** File I/O operations (reading rules, writing logs, accessing memory) are scattered directly within various scripts and the C++ application. This tightly couples the logic to a specific file format and directory structure.
*   **Suggestion:** Introduce a dedicated set of scripts or C++ classes that act as a data access layer. This layer would be solely responsible for all interactions with the file system (e.g., `get_rule(id)`, `write_log(message)`). The core logic would call these functions instead of `cat`, `grep`, or `fopen` directly. This makes it easier to change file formats (e.g., from `.txt` to `.xml` or `.json`) or mock data for unit tests.

### 4. Feature-Based Module Structure

*   **Observation:** The current structure is organized by function type (e.g., all routes in one place, all controllers in another).
*   **Suggestion:** For larger applications, consider organizing by feature. For example, a `modules/` directory could contain subdirectories for `planning`, `ethics`, and `execution`. Each feature directory would contain its own scripts, rules, and test cases. This approach improves encapsulation and allows teams to work on features with greater autonomy.