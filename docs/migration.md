# Migration and Discrepancy Report

This document outlines the identified discrepancies between the project's documentation and its codebase. The goal is to provide a clear path for aligning the two, ensuring that developers have accurate and reliable information.

## Methodology
To identify these conflicts, we performed a systematic review comparing documentation sources against the current `main` branch. The review process included:

1.  **API Documentation vs. Implementation:** Comparing public API signatures in documentation (e.g., READMEs, JSDoc, Swagger/OpenAPI specs) with the actual function and method signatures in the source code.
1.  **Script/Tool Documentation vs. Implementation:** Comparing documented command-line arguments, flags, and behaviors of shell scripts and the C++ interface with their actual implementation.
2.  **Configuration Guides vs. Code:** Validating documented configuration options, environment variables, and default values against their implementation in configuration files and scripts.
3.  **Architectural Diagrams vs. Code Structure:** Checking if the high-level component diagrams and data flow descriptions in the documentation accurately reflect the current module dependencies and interactions in the codebase.
4.  **Inline Code Comments vs. Code:** Auditing inline documentation (like C++ comments and script headers) for consistency with the function's behavior, parameters, and return values.

---

## Identified Conflicts

Below is a list of identified conflicts, categorized by the area of the project. Each item includes a description of the conflict and a suggested resolution.

### 1. Script Arguments & Behavior

| Script & Argument | Documentation Discrepancy | Code Implementation | Suggested Action |
| :---------------- | :------------------------ | :------------------ | :--------------- |
| `scripts/ethics_bias_checker.sh --file` | Documented as a valid way to check a file's content. | The `--file` argument is ignored; the script only accepts `--text` or piped input. | Remove the `--file` argument from documentation or implement the functionality. |
| `scripts/run_planner.sh --verbose` | Not documented, but would be useful for debugging the planning stages. | The script has no verbosity flag; all output goes to stdout. | Add a `--verbose` flag to the script and document its usage. |
| ... | ... | ... | ... |

### 2. C++ Interface Functions

| File Path & Function | Documentation Discrepancy | Code Implementation | Suggested Action |
| :------------------- | :------------------------ | :------------------ | :--------------- |
| `interface/quantaporto_interface.cpp` `load_rules(path)` | Header comment states it returns `bool` for success/failure. | The function returns an `int` (0 for success, -1 for failure). | Update the header comment to specify the `int` return type and its meaning. |
| `interface/quantaporto_interface.cpp` `run_pipeline()` | `docs/plan.md` implies this function takes a task ID as an argument. | The function takes no arguments and reads the task from a predefined file path. | Clarify in `docs/plan.md` that the function is parameter-less. |
| ... | ... | ... | ... |

### 3. Configuration

| Configuration Item | Documentation Discrepancy | Code Implementation | Suggested Action |
| :----------------- | :------------------------ | :------------------ | :--------------- |
| `LOG_FILE_PATH` | `docs/plan.md` states the C++ interface logs to `data/logs/interface.log`. | The path is hardcoded in the C++ source as `logs/quantaporto.log`. | Update `docs/plan.md` to reflect the correct log file path. |
| `RULES_FILE` | `docs/plan.md` specifies rules are in `config/rules.txt`. | The C++ interface is hardcoded to load `rules/rules.xml`. | Align the documentation and implementation on a single path and format. |
| ... | ... | ... | ... |

### 4. Installation & Setup

| Guide Section | Documentation Discrepancy | Required Steps | Suggested Action |
| :------------ | :------------------------ | :------------- | :--------------- |
| "Dependencies" | `README.md` only lists `Bash`. | The C++ interface requires `g++` and `make` to be compiled. | Update the "Dependencies" section in `README.md` to include build tools. |
| "Building the Interface" | No instructions are provided for compiling `quantaporto_interface.cpp`. | A user must run `g++ -o quantaporto_interface interface/quantaporto_interface.cpp`. | Add a "Build Instructions" section to the `README.md`. |
| ... | ... | ... | ... |

### 5. External Library Dependencies

The project vision emphasizes a lightweight, dependency-free architecture. The following external tools and libraries are mentioned in the documentation and conflict with this principle.

| Library/Tool | Documented Usage | Mitigation Strategy |
| :--- | :--- | :--- |
| C++ XML Parser | `docs/plan.md` suggests C++ libraries for the daemon's PQL parser. | To maintain a dependency-free user experience, the chosen library's source code will be bundled directly in the project repository (e.g., in a `libs/` directory) and compiled as part of the `quantaporto_interface` build. This contains the dependency within the project, requiring no separate installation. |
| ... | ... | ... |

---

## Next Steps

1.  **Prioritize:** Review the list of conflicts and prioritize them based on impact. Critical issues (e.g., incorrect setup instructions) should be addressed first.
2.  **Assign:** Create tickets or issues in the project management tool for each conflict and assign them to the appropriate team members.
3.  **Resolve:** Update either the code or the documentation to resolve the discrepancy. Prefer updating documentation unless the code's behavior is incorrect.
4.  **Verify:** Once a fix is merged, verify that the documentation and code are now in sync.