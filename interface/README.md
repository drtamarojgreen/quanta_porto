# QuantaPorto C++ Interface

This directory contains the source code for the core QuantaPorto C++ application. This application serves as a robust, high-performance engine that replaces the complex logic previously handled by numerous shell scripts.

## Mission

The C++ interface is designed to be a stateful, long-running daemon that manages the entire lifecycle of LLM interaction. It handles task parsing, prompt generation, direct model inference, rule enforcement, and the reflective consequence loop.

By centralizing this logic, we gain:
- **Performance**: Direct library calls to `llama.cpp` and XML parsers are significantly faster than shelling out to external tools.
- **Robustness**: Superior error handling, type safety, and state management.
- **Maintainability**: Complex logic is easier to read, debug, and extend in a structured C++ codebase.

## Architecture

The application follows the design outlined in `docs/plan.md`, consisting of several key components:

- **Scheduler**: The main application loop that orchestrates the other components.
- **PQL Parser**: Reads and validates PQL and rule files.
- **Prompt Generator**: Constructs prompts from parsed tasks.
- **LLM Runner**: Directly interfaces with `llama.cpp` to run inference.
- **Rule Engine**: Evaluates LLM output against the configured rules.
- **Consequence Engine**: Manages the reflective loop and other consequences for rule violations.

## Shell Script to C++ Component Mapping

The following table shows which shell scripts' functionalities will be absorbed into the C++ application. The original scripts will either be retired or simplified into high-level orchestrators that call this C++ executable.

| Original Shell Script             | C++ Component Responsibility             | Status                               |
| --------------------------------- | ---------------------------------------- | ------------------------------------ |
| `llm_infer.sh` (and `llama-cli`)  | `LLM Runner`                             | Port to C++ (direct library calls)   |
| `parse_pql.sh`                    | `PQL Parser`                             | Port to C++ (using XML library)      |
| `rule_enforcer.sh`                | `Rule Engine`                            | Port to C++                          |
| `pql_test_and_consequence.sh`     | `Consequence Engine`                     | Port to C++                          |
| `task_manager.sh`                 | `Scheduler` / Main Loop                  | Port to C++                          |
| `enhanced_task_manager.sh`        | `Scheduler` / Main Loop                  | Port to C++                          |
| `validation_loop.sh`              | `PQL Parser` / `Rule Engine`             | Port to C++                          |
| `run_task.sh`                     | (External Caller)                        | Simplify to call C++ executable      |
| `run_planner.sh`                  | (External Caller)                        | Simplify to call C++ executable      |
| `self_chat_loop.sh`               | (External Caller)                        | Simplify to call C++ executable      |
| `code_analysis.sh`                | (N/A - Utility)                          | Remains a standalone shell script    |

## Usage

The C++ application will be designed to be called from the command line with different modes of operation.

```bash
# Example: Run a single task from a PQL file
./quantaporto_interface --run-pql-task rules/pql_sample.xml --task-id=task-001

# Example: Run the full planning loop
./quantaporto_interface --run-planner
```