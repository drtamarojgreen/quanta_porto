# QuantaPorto Implementation Plan

This plan organizes tasks by directory and function, enabling modular implementation by autonomous agents. Each section includes the objective, implementation steps, and expected outputs.

---

## config/

### priorities.txt
- **Objective**: Define task priorities for LLM scheduling.
- **Tasks**:
  - Parse this file before prompt assignment.
  - Integrate priority selection logic in `interface/quantaporto_interface.cpp`.
- **Output**: Map<string, int> of tasks with priority levels.

### rules.xml
- **Objective**: Define enforcement logic for rule violations in a structured XML format.
- **Tasks**:
  - Load and parse in `interface/quantaporto_interface.cpp`.
  - Match against logs or prompt outputs.
  - Trigger enforcement via `scripts/rule_enforcer.sh`.
- **Output**: Parsed rule set used during consequence evaluation.

---

## docs/

### README.md
- **Objective**: Provide project overview and documentation anchor.
- **Tasks**:
  - Validate that all scripts, schemas, and workflows referenced are current.
  - Generate/update with planning and interface changes.
- **Output**: Human-readable documentation, bot validation target.

---

## interface/

### quantaporto_interface.cpp
- **Objective**: C++ scheduler and command interface for Bash-driven LLM workflows.
- **Tasks**:
  - Load rules and priorities.
  - Monitor timeout marker.
  - Launch pipeline via `run_task.sh`.
  - Log all decisions to `logs/quantaporto.log`.
- **Output**: Logged execution events and dynamic prompt control.

---

## memory/

### development_lessons.txt
- **Objective**: Retain historical insights from development.
- **Tasks**:
  - Include references in `plan_code_tasks.sh` or `strategize_project.sh`.
  - Use for reflective validation loop.
- **Output**: Auxiliary knowledge injected into planning pipeline.

### test.txt
- **Objective**: Placeholder for experimental memory input/output.
- **Tasks**:
  - Use during pipeline testing or input simulation.
  - Replace with structured content in long-term memory planning.
- **Output**: Dynamic memory segment during experimentation.

---

## prompts/

### input_prompt.txt
- **Objective**: Active prompt loaded by LLM pipeline.
- **Tasks**:
  - Replace dynamically based on priority mapping.
  - Use by `run_task.sh` and `interface/quantaporto_interface.cpp`.
- **Output**: Prompt consumed by core execution engine.

---

## rules/

### pql.xsd
- **Objective**: Schema for validating PQL commands.
- **Tasks**:
  - Run via `parse_pql.sh` or `validation_loop.sh`.
  - Trigger enforcement if schema invalid.
- **Output**: Validation report on `pql_sample.xml`.

### pql_sample.xml
- **Objective**: Example command definition for testing.
- **Tasks**:
  - Test parsing and consequence triggering.
  - Include in unit tests.
- **Output**: Parsed task structure for pipeline initiation.

### rules.xsd
- **Objective**: Schema for validating structured rule definitions.
- **Tasks**:
  - Validate `rules.xml` structure.
  - Used by `validation_loop.sh`.
- **Output**: Rule format integrity report.

---

## scripts/

### check_server_status.sh
- **Objective**: Verify that the LLM server is running and reachable.
- **Tasks**:
  - Send a request to the server's root URL.
  - Report status and exit with an error if the server is unreachable.
- **Output**: A status message indicating if the server is running.

### code_analysis.sh
- **Objective**: Perform static analysis on the project's shell scripts.
- **Tasks**:
  - Count tests, check documentation status, find orphaned files, and scan for TODOs.
- **Output**: A Markdown report with the analysis results.

### define_requirements.sh
- **Objective**: Generate a list of requirements from a strategy plan.
- **Tasks**:
  - Read a strategy plan file.
  - Use the LLM to generate a list of requirements.
- **Output**: A file containing the generated requirements.

### dev_team_test.sh
- **Objective**: Test the LLM's ability to simulate a developer team.
- **Tasks**:
  - Send a multi-role chat prompt to the LLM server.
  - Parse and display the assistant's response.
- **Output**: The LLM's response to the prompt.

### enhanced_task_manager.sh
- **Objective**: An advanced runner for tasks that require LLM inference and ethics checking.
- **Tasks**:
  - Run LLM inference.
  - Perform an ethics and bias check on the output.
  - Trigger the rule enforcer and retry if the check fails.
- **Output**: The successful output from the LLM.

### ethics_bias_checker.sh
- **Objective**: Detect ethics and bias issues in text.
- **Tasks**:
  - Analyze text for various types of bias using multiple methods.
  - Calculate a severity score and generate mitigation suggestions.
- **Output**: A JSON or text report of the findings.

### ethics_monitor.sh
- **Objective**: Continuously monitor LLM output for ethics violations.
- **Tasks**:
  - Tail a specified output file.
  - Check each new line against a set of ethics rules.
  - Invoke the rule enforcer if a violation is found.
- **Output**: Logs of any detected violations.

### generate_prompt.sh
- **Objective**: Assemble a structured LLM prompt from a PQL task.
- **Tasks**:
  - Extract a task's description, commands, and criteria from a PQL file.
  - Combine them with document content piped via stdin.
- **Output**: A formatted prompt ready to be sent to an LLM.

### llm_infer.sh
- **Objective**: (Empty script)

### llm_infer_server.sh
- **Objective**: Send a prompt to a running LLM server for inference.
- **Tasks**:
  - Construct a JSON payload with the prompt and parameters.
  - Send the payload to the server and parse the response.
- **Output**: The generated text content from the LLM.

### parse_pql.sh
- **Objective**: Parse and validate PQL task files.
- **Tasks**:
  - List tasks, extract commands or criteria, and validate the XML file against its schema.
- **Output**: The requested information from the PQL file.

### plan_code_tasks.sh
- **Objective**: A multi-stage pipeline for planning development tasks.
- **Tasks**:
  - Use an LLM to break requirements into tasks, prioritize them, and revise them.
- **Output**: A prioritized and verified list of tasks.

### polling.sh
- **Objective**: A command runner that executes a command in the background.
- **Tasks**:
  - Display a "thinking" indicator while the command runs.
  - Capture and print the command's output.
- **Output**: The output of the executed command.

### quantaporto_daemon.sh
- **Objective**: A daemon that monitors a queue and dispatches tasks.
- **Tasks**:
  - Move tasks from the pending queue to the in-progress queue.
  - Invoke the worker script to process the task.
- **Output**: Logs of its activities.

### quantaporto_worker.sh
- **Objective**: Process a single PQL task file.
- **Tasks**:
  - Parse a task's XML file to extract the task ID and commands.
  - Generate an executable shell script for the task.
- **Output**: An executable shell script.

### rule_enforcer.sh
- **Objective**: Enforce actions based on rule violations.
- **Tasks**:
  - Look up a violation in the ethics rules file.
  - Trigger one or more consequences.
- **Output**: Logs of the actions taken.

### run_inference.sh
- **Objective**: (Empty script)

### run_pql_tests.sh
- **Objective**: A test-and-remediate cycle for the LLM.
- **Tasks**:
  - Run PQL and ethics tests.
  - Apply a reward, remediation, or a "soft consequence" based on the results.
- **Output**: Logs of the test results and actions taken.

### self_chat_loop.sh
- **Objective**: Simulate a conversation between two AI personas.
- **Tasks**:
  - Generate responses for each persona using the LLM.
  - Check each response for ethics violations.
- **Output**: A log of the conversation.

### send_prompt.sh
- **Objective**: Send a prompt to the local LLM using the `llama-cli` tool.
- **Tasks**:
  - Assemble a prompt from a command-line argument and/or stdin.
  - Call `llama-cli` and parse the output.
- **Output**: The generated text from the LLM.

### strategize_project.sh
- **Objective**: Generate a set of sub-strategies from a list of project goals.
- **Tasks**:
  - Read a file of project goals.
  - Use the LLM to generate a list of sub-strategies.
- **Output**: A file containing the generated sub-strategies.

### test_server.sh
- **Objective**: A health check and test query for the LLM server.
- **Tasks**:
  - Check if the server is reachable.
  - Send a test prompt and parse the response.
- **Output**: The LLM's response to the test prompt.

### utils.sh
- **Objective**: Provide common utility functions for the other scripts.
- **Tasks**:
  - Set up the environment, log messages, and check for dependencies.
- **Output**: None.

---

## Top-Level Artifacts

### .timeout
- **Objective**: Prevent retry after failed runs.
- **Tasks**:
  - Modified by `interface/quantaporto_interface.cpp` after failure.
- **Output**: Polling suspension signal.

### main
- **Objective**: Executable entry point or stub binary.
- **Tasks**:
  - Validate link to `interface/quantaporto_interface.cpp`.
- **Output**: Startup trigger for scheduling engine.

### quantaporto_interface
- **Objective**: Compiled binary for polling-based engine.
- **Tasks**:
  - Schedule pipeline runs via prompts and timeout logic.
- **Output**: Console logs, rule enforcement decisions.

### README.md
- **Objective**: Root-level documentation.
- **Tasks**:
  - Synchronize with `docs/README.md`.
- **Output**: User-facing overview.

# QuantaPorto Development Priorities

This document outlines the development roadmap, ordered by priority.

## P1: Core Functionality (MVP)
These tasks are essential for a minimum viable product.

1.  **Implement Core LLM Runner (`scripts/run_llm.sh`):**
    -   Load the local GGML model.
    -   Accept a prompt from stdin or a file.
    -   Execute the model and capture the raw output.
    -   This is the absolute highest priority; the system is non-functional without it.

2.  **Implement Prompt Generation (`scripts/generate_prompt.sh`):**
    -   Parse a PQL file (e.g., `pql/sample_commands.pql`).
    -   Assemble the extracted parts into a structured prompt suitable for the LLM.
    -   Parsing logic will be handled by native shell tools or by the C++ interface.
    -   This script will be the primary input for `run_llm.sh`.

## P2: Rule & Consequence Engine
These tasks implement the unique cognitive-shaping features of QuantaPorto.

3.  **Define Initial Rule Set (`rules/rules.xml`):**
    -   Finalize the XML structure for rules, conditions, and consequences.
    -   Create a corresponding `rules.xsd` for validation.
    -   Populate `rules.xml` with 3-5 foundational rules (e.g., "must not refuse", "must use specified format").

4.  **Implement Rule Enforcement (`scripts/enforce_rules.sh`):**
    -   Accept an LLM response as input.
    -   Parse `rules.xml` to get the active rules.
    -   Evaluate the response against the rules and output a status (e.g., "PASS" or "FAIL:<rule_id>").

5.  **Implement Reflection Loop (`scripts/reflect_and_retry.sh`):**
    -   Triggered when `enforce_rules.sh` outputs a failure.
    -   Looks up the consequence for the failed rule in `rules.xml`.
    -   Generates a new "reflective" prompt and creates a recursive loop back to the prompt generator.

## P3: Usability and Expansion
These tasks improve the developer/user experience and expand the system's capabilities.

6.  **Enhance Parsers and Tooling:**
    -   Add functionality to parse `rules.xml` and list rules/consequences.
    -   Improve logging in `logs/session.log` to capture the full flow: PQL -> Prompt -> Response -> Rule Check -> Reflection.

7.  **Documentation and Examples:**
    -   Keep `README.md` and all sample files (`.pql`, `.xml`) updated as features are added.

---

## P4: Internal XML Tooling
This priority focuses on creating a self-contained, dependency-free XML utility to handle PQL files, aligning with the project's core principles.

8.  **Design a Simple XML Parser and Serializer:**
    -   **Objective:** Create a lightweight, native utility for reading and writing PQL-formatted XML files without external libraries.
    -   **Rationale:** A custom utility tailored to the PQL schema will be faster, smaller, and more secure than a general-purpose library. It removes dependencies like `xmlstarlet` and ensures the entire application can run in a minimal environment.

9.  **Implement the XML Parser (Deserializer):**
    -   **Strategy:** Implement a simple, non-validating parser in C++ that can be compiled into the main `quantaporto_interface` binary or as a small standalone utility.
    -   **Approach:**
        -   Read the XML file line by line.
        -   Use basic string manipulation and regular expressions to identify tags, attributes, and content.
        -   It will only need to support a subset of XML: elements, attributes, and text content. It will not support comments, CDATA, or namespaces.
        -   The parser will expose a function to query data using a simplified path syntax (e.g., `task[@id='t01']/description`).
    -   **Integration:** The `scripts/parse_pql.sh` script will be updated to call this internal utility to extract data from PQL files.

10. **Implement the XML Serializer:**
    -   **Strategy:** Create a C++ function or utility that can generate a well-formed XML string from an in-memory data structure (e.g., a `std::map` or a custom struct).
    -   **Approach:**
        -   The function will take key-value pairs representing the PQL task.
        -   It will construct the XML string, ensuring proper tag nesting, indentation, and escaping of special characters (`&`, `<`, `>`).
    -   **Integration:** This will be used by components that need to create or modify PQL files programmatically.

11. **Replace Existing XML Logic:**
    -   **Objective:** Audit all shell scripts and C++ source code to replace any remaining calls to external XML tools (`xmlstarlet`, `grep`/`sed` for XML parsing) with the new internal utility.
    -   **Tasks:**
        -   Refactor `scripts/generate_prompt.sh`.
        -   Refactor `scripts/parse_pql.sh`.
        -   Ensure the C++ daemon uses the internal functions directly for maximum performance.

---

# Code Analysis Metrics

This section defines the key metrics for evaluating code quality.

- **Cyclomatic Complexity**: Measures the complexity of a program's control flow. Lower is better.
- **Halstead Complexity**: Measures the vocabulary and operators in the code. Lower is better.
- **Maintainability Index**: A composite metric that combines Halstead complexity, cyclomatic complexity, and lines of code. Higher is better.
- **Code Coverage**: The percentage of code that is executed during testing. Higher is better.

---

# Code Analysis Script Enhancements

This section lists possible enhancements to the code analysis script.

- **Automated Reporting**: The script should generate a report of the code analysis metrics in a structured format (e.g., JSON, HTML).
- **Historical Analysis**: The script should be able to track code quality metrics over time to identify trends.
- **Integration with CI/CD**: The script should be integrated into the CI/CD pipeline to provide continuous feedback on code quality.
- **Customizable Thresholds**: The script should allow users to define custom thresholds for each metric to trigger warnings or failures.

## C++ Daemon Design (Alternative Implementation)

**Note:** The following describes a C++ based implementation of a task management pipeline. While the repository contains C++ source files in the `interface/` directory that align with this design, the primary, documented pipeline currently in use is the shell script-based system described in the `scripts/` section.

The C++ daemon is the core component of the QuantaPorto system. It is responsible for orchestrating the entire workflow, from parsing PQL commands to enforcing rules and managing the LLM lifecycle.

### Components

The daemon will be composed of the following key components:

1.  **PQL Parser:**
    -   **Objective:** Parse PQL (`.pql`) files to extract commands, criteria, and other metadata.
    -   **Implementation:** Use the application's internal, lightweight XML parsing capabilities to read and validate PQL files against the `pql.xsd` schema. This avoids external library dependencies for the end-user.
    -   **Output:** A structured in-memory representation of the PQL commands.

2.  **Prompt Generator:**
    -   **Objective:** Assemble a structured prompt for the LLM based on the parsed PQL commands.
    -   **Implementation:** This component will take the output from the PQL Parser and format it into a text-based prompt that the LLM can understand.
    -   **Output:** A string containing the fully-formed prompt.

3.  **LLM Runner:**
    -   **Objective:** Execute the local GGML model with the generated prompt.
    -   **Implementation:** This component will be responsible for loading the GGML model, passing the prompt to it, and capturing the raw output. It will use the `ggml` library for this purpose.
    -   **Output:** The raw text output from the LLM.

4.  **Rule Engine:**
    -   **Objective:** Enforce the rules defined in `rules.xml` on the LLM's output.
    -   **Implementation:** The Rule Engine will parse `rules.xml` to get the active rules. It will then evaluate the LLM's response against these rules.
    -   **Output:** A status indicating whether the response passed or failed, and if it failed, which rule was violated.

5.  **Reflection Engine:**
    -   **Objective:** Generate a "reflective" prompt when a rule is violated.
    -   **Implementation:** When the Rule Engine reports a failure, the Reflection Engine will look up the consequence for the failed rule in `rules.xml`. It will then generate a new prompt that encourages the LLM to reflect on its mistake and try again.
    -   **Output:** A new prompt that is fed back into the Prompt Generator.

6.  **Scheduler:**
    -   **Objective:** Manage the overall workflow and schedule tasks.
    -   **Implementation:** The Scheduler will be the main loop of the daemon. It will coordinate the other components, manage the flow of data between them, and handle retries and other exceptional circumstances.
    -   **Output:** Logs and status updates.

### Workflow

The overall workflow of the C++ daemon will be as follows:

1.  The daemon is started.
2.  The Scheduler kicks off the main loop.
3.  The PQL Parser reads a PQL file.
4.  The Prompt Generator creates a prompt.
5.  The LLM Runner executes the LLM with the prompt.
6.  The Rule Engine evaluates the LLM's output.
7.  If the output passes, the task is complete.
8.  If the output fails, the Reflection Engine generates a new prompt and the process repeats from step 4.

### Management and Reliability

The daemon will be designed with the following principles in mind to ensure it is robust and easy to manage:

*   **Memory Management:**
    *   Memory will be allocated and deallocated carefully to prevent memory leaks.
    *   Smart pointers (`std::unique_ptr` and `std::shared_ptr`) will be used to manage object lifetimes and prevent dangling pointers.
    *   Resource acquisition will follow the RAII (Resource Acquisition Is Initialization) idiom.

*   **Loop Prevention:**
    *   The daemon will include a mechanism to prevent infinite loops.
    *   A maximum number of retries will be configured for the reflection loop. If the LLM fails to produce a valid response after the maximum number of retries, the task will be marked as failed and the daemon will move on to the next task.

*   **Start/Stop/Monitor:**
    *   The daemon will be easy to start and stop using standard system commands (e.g., `systemctl start quantaporto`, `systemctl stop quantaporto`).
    *   It will provide a clear and concise logging output that can be used to monitor its status and diagnose problems.
    *   A separate monitoring process will be implemented to watch the daemon and restart it if it crashes.

### Pseudocode

Here is some pseudocode to illustrate how the daemon will work:

```cpp
class PQLParser {
public:
  PQLCommand parse(string pql_file) {
    // Load and parse the PQL file using an XML parser.
    // Validate the PQL file against the pql.xsd schema.
    // Extract the commands, criteria, and other metadata.
    // Return a structured PQLCommand object.
  }
};

class PromptGenerator {
public:
  string generate(PQLCommand command) {
    // Assemble a structured prompt based on the PQL command.
    // Return the prompt as a string.
  }
};

class LLMRunner {
public:
  string run(string prompt) {
    // Load the GGML model.
    // Pass the prompt to the model.
    // Capture and return the raw output from the model.
  }
};

class RuleEngine {
public:
  RuleResult evaluate(string response) {
    // Parse rules.xml to get the active rules.
    // Evaluate the response against the rules.
    // Return a RuleResult object with the status and any violations.
  }
};

class ReflectionEngine {
public:
  string reflect(RuleResult result) {
    // Look up the consequence for the failed rule in rules.xml.
    // Generate a new "reflective" prompt.
    // Return the new prompt.
  }
};

class Scheduler {
public:
  void run() {
    while (true) {
      // Get the next PQL file from the queue.
      PQLCommand command = pql_parser.parse(pql_file);
      string prompt = prompt_generator.generate(command);
      int retries = 0;
      while (retries < MAX_RETRIES) {
        string response = llm_runner.run(prompt);
        RuleResult result = rule_engine.evaluate(response);
        if (result.is_pass()) {
          // The task is complete.
          break;
        } else {
          // The task failed, so generate a reflective prompt and retry.
          prompt = reflection_engine.reflect(result);
          retries++;
        }
      }
    }
  }

private:
  PQLParser pql_parser;
  PromptGenerator prompt_generator;
  LLMRunner llm_runner;
  RuleEngine rule_engine;
  ReflectionEngine reflection_engine;
};

int main() {
  Scheduler scheduler;
  scheduler.run();
  return 0;
}
