# Modularity Enhancement Opportunities

This document identifies key areas in the codebase that could be refactored to improve modularity. A more modular design will make the application easier to understand, maintain, test, and scale.

---

### 1. Separate Core Logic from Script Orchestration

*   **Observation:** Core logic (like rule parsing and consequence evaluation) is mixed between the C++ interface and various shell scripts. This creates a monolithic structure that is difficult to manage and test.
*   **Suggestion:**
    *   **Core Engine (C++):** The C++ application (`quantaporto_interface`) should be solely responsible for high-performance tasks: parsing rules, managing state, and executing the core decision-making loop.
    *   **Orchestration (Shell Scripts):** The `scripts/` directory should contain scripts that act as the "glue," responsible for file system operations, invoking the C++ engine, and chaining tasks together in the pipeline.
    *   **Entry Point:** The main entry point (`main` or `run.sh`) should be lean, primarily responsible for setting up the environment and starting the C++ daemon or the main task pipeline.

### 2. Abstract Data Storage Interactions

*   **Observation:** File I/O operations (reading rules, writing logs, accessing memory) are scattered directly within various scripts and the C++ application. This tightly couples the logic to a specific file format and directory structure.
*   **Suggestion:** Introduce a dedicated set of scripts or C++ classes that act as a data access layer. This layer would be solely responsible for all interactions with the file system (e.g., `get_rule(id)`, `write_log(message)`). The core logic would call these functions instead of `cat`, `grep`, or `fopen` directly. This makes it easier to change file formats (e.g., from `.txt` to `.xml` or `.json`) or mock data for unit tests.

### 3. Consolidate Utility Functions

*   **Observation:** Common helper functions, such as data formatters, validators, or constants, are either duplicated across different files or defined in places where they don't belong.
*   **Suggestion:** Reinforce the use of `scripts/utils.sh` as the central location for all shared, reusable utility functions. This promotes code reuse and makes the helpers easier to find and maintain.

### 4. Feature-Based Module Structure

*   **Observation:** The current structure is organized by function type (e.g., all routes in one place, all controllers in another).
*   **Suggestion:** For larger applications, consider organizing by feature. For example, a `modules/` directory could contain subdirectories for `planning`, `ethics`, and `execution`. Each feature directory would contain its own scripts, rules, and test cases. This approach improves encapsulation and allows teams to work on features with greater autonomy.