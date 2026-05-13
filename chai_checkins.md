# Checkins

## Environmental Facts
- **Scripts**: 23 shell scripts identified in `scripts/` (e.g., `run_task.sh`, `parse_pql.sh`, `check_server_status.sh`).
- **Compiler**: `g++` (Ubuntu 13.3.0-6ubuntu2~24.04.1).
- **Build Tool**: `GNU Make 4.3`.
- **Filesystem**: Project root contains `scripts/`, `interface/`, `docs/`, `memory/`, `rules/`, `tests/`.
- **Runtime**: Bash shell and C++17.
- **Config**: `environment.txt` is the primary source of truth for paths and settings.

## SDD Restrictions
- **Pattern Restrictions**:
    - No raw `std::system()` calls without explicit logging to `logs/quantaporto.log`.
    - No hardcoded paths; all paths must be derived from `Config`.
    - No empty catch blocks.
- **Tool Restrictions**:
    - Compiler: `g++` with `-std=c++17`.
    - Libraries: Standard C++17 only.
- **Architectural Restrictions**:
    - Minimalist design: Keep logic for the Porto Manager within a single source file `porto_manager.cpp` where feasible.
    - Avoid unnecessary abstraction layers.
- **Validation Restrictions**:
    - All sub-process executions must capture and evaluate exit codes.
    - Mandatory logging of all script launches and completions.

## Task Status
- [x] Initializing SDD artifacts.
- [x] Fact discovery of scripts and processes.
- [x] Define Restrictions.
- [x] Design C++ console application.
- [x] Implement C++ console application.
- [x] Verify implementation.
