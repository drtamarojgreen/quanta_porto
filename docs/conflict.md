# Documentation & Codebase Conflicts

This document outlines observed discrepancies between the project's documentation and the actual behavior of the application code. Resolving these conflicts is crucial for developer onboarding, maintenance, and ensuring a reliable user experience.

---

### 1. Script Parameter Discrepancy

*   **Conflict:** The documentation in `docs/ethics.md` states the `scripts/ethics_bias_checker.sh` script accepts a `--file` argument to check a file's content.
*   **Code Reality:** The script only accepts input via the `--text` argument or standard input, ignoring the `--file` parameter entirely.
*   **Impact:** Users following the documentation will find the script doesn't work as expected for file-based checks, leading to confusion and broken pipelines.

### 2. Configuration File Format Mismatch

*   **Conflict:** The implementation plan (`docs/plan.md`) specifies that the C++ interface (`quantaporto_interface.cpp`) should parse `config/rules.txt` for its rule definitions.
*   **Code Reality:** The C++ application is hardcoded to look for and parse `rules/rules.xml`, completely ignoring the file in the `config/` directory.
*   **Impact:** The application is not configurable as intended. Changes to `config/rules.txt` have no effect, and developers must edit the XML file in a different directory, contrary to the plan.

### 3. Inconsistent Logging Behavior

*   **Conflict:** The `plan.md` document states that the C++ interface logs all decisions to `data/logs/interface.log`.
*   **Code Reality:** The C++ application does not create a `data/` directory and instead writes its logs to `logs/quantaporto.log`.
*   **Impact:** Automated log monitoring tools or developers looking for logs in the documented location will fail to find them, hindering debugging and operational oversight.