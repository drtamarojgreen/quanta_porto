# Porto Manager Design Specification

## Overview
The Porto Manager is a C++ console terminal application designed to manage and execute the porto scripts and processes within the QuantaPorto framework. It follows Sorrel Driven Development (SDD) principles, ensuring structural enforcement and empirical verification.

## Interface
The application provides an interactive Command Line Interface (CLI).

### Command Set
- `list`: Displays a numbered list of all executable porto scripts found in the `scripts/` directory.
- `run <index|name>`: Executes the specified script.
    - `<index>`: The number assigned to the script in the `list` command.
    - `<name>`: The filename of the script (e.g., `run_task.sh`).
- `help`: Displays a summary of available commands.
- `exit`: Terminates the application.

## Execution Flow
1. **Initialization**:
    - Load configuration from `environment.txt` using the `Config` class.
    - Validate essential paths (e.g., `scripts/`, `logs/`).
2. **Script Discovery**:
    - Scan the `scripts/` directory for files ending in `.sh`.
    - Filter for executable files.
    - Store the discovered scripts in an internal registry (vector/map).
3. **Interactive Loop**:
    - Display the `Porto Manager > ` prompt.
    - Wait for user input.
    - Parse the input into a command and arguments.
4. **Command Execution**:
    - **list**: Iterate through the registry and print script names.
    - **run**:
        - Resolve the script path from the registry.
        - Log the execution attempt to `logs/quantaporto.log`.
        - Execute the script using a controlled sub-process.
        - Capture the exit status and log the result.
        - Display the script output (or a summary) to the user.
    - **help**: Print command documentation.
    - **exit**: Break the loop and perform cleanup.

## Structural Restrictions
- **No Hardcoded Paths**: All script and log paths must be derived from `Config`.
- **Mandatory Logging**: Every execution attempt and result must be logged.
- **Exit Code Verification**: The application must report if a script failed (non-zero exit code).
- **Minimal Dependencies**: Use only Standard C++17 and existing project components (`Config`).

## Architecture
- **Source File**: `interface/porto_manager.cpp`
- **Dependencies**: `interface/Config.h`, `interface/Config.cpp`
