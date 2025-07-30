# QuantaPorto

---

**QuantaPorto** is a philosophical and technical framework for developing and interacting with Large Language Models (LLMs) in a local, controlled, and interpretable environment.

> *“We didn’t just build a system. We raised a mind.”*

---

## 🌌 What is QuantaPorto?

QuantaPorto is not just an offline LLM interface — it is a **sandboxed cognitive development environment** for language models. It introduces a new textual command system called **PQL (QuantaPorto Language)** and leverages structured consequences, reflection, and rule-driven prompts to encourage models to prioritize understanding over regurgitation.

---


## 🧠 Core Concepts

### 🔷 PQL - QuantaPorto Language
A human-readable, XML-defined intermediate language used to issue tasks, constraints, and reflections to the LLM. Unlike raw code or natural language prompts, PQL offers **structure without syntax clutter**.

### 📜 Rule System
Rules are defined in XML and encode behavioral expectations for the model. Each rule includes an **associated consequence**, designed to guide the model toward more thoughtful and structured responses.

### 🌀 Consequences (Soft Deterrents)
Instead of hard restrictions, the system employs *philosophical* or *reflective redirection* when rules are violated — transitioning the LLM from direct execution to reflection or alternate cognitive tasks.

### 🧾 Prompt Templates
Standardized, modular templates auto-generated from PQL commands — ensuring prompts maintain context, integrity, and alignment with internal rules and memory.

### 📁 Local Autonomy
QuantaPorto runs entirely **offline**. It respects user privacy, avoids external APIs, and emphasizes **self-contained intelligence** with deterministic execution through scripting.

---

## 📂 Project Structure

```plaintext
QuantaPorto/
├── config/
│   ├── priorities.txt
│   └── rules.txt
├── docs/
│   └── README.md
├── interface/
│   └── quantaporto_interface.cpp
├── memory/
│   ├── development_lessons.txt
│   └── test.txt
├── prompts/
│   └── input_prompt.txt
├── rules/
│   ├── pql.xsd
│   ├── pql_sample.xml
│   └── rules.xsd
├── scripts/
│   ├── define_requirements.sh
│   ├── enhanced_task_manager.sh
│   ├── memory_review.sh
│   ├── parse_pql.sh
│   ├── plan_code_tasks.sh
│   ├── pql_test_and_consequence.sh
│   ├── rule_enforcer.sh
│   ├── run_planner.sh
│   ├── run_task.sh
│   ├── self_chat_loop.sh
│   ├── strategize_project.sh
│   ├── task_manager.sh
│   └── validation_loop.sh
├── .timeout
├── main
├── quantaporto_interface
└── README.md
```

---

## ⚙️ Getting Started

This section provides instructions on how to set up and use the tools within the QuantaPorto framework.

### Dependencies

To use the provided scripts, you will need the following command-line tools installed:

*   **Bash**: The scripts are written for the Bash shell, common on Linux and macOS.


### Using the Parser

The `parse_pql.sh` script is your primary interface for interacting with `tasks.xml`. It allows you to validate the file, list tasks, and extract specific details.

Navigate to the `scripts` directory to run these commands:

```bash
# 1. Validate the tasks.xml file against its schema
./parse_pql.sh validate

# 2. List all available task IDs and their descriptions
./parse_pql.sh list

# 3. Get the specific commands for a task
./parse_pql.sh commands task-001
```

### Scripts

The `scripts/` directory contains a rich set of tools for managing the entire lifecycle of the QuantaPorto system, from planning and task execution to self-reflection and analysis. Below is a breakdown of the key scripts and their functions.

#### Core Task & Project Management

*   **`run_planner.sh`**: The main control loop for the AI's "thinking" process. It orchestrates the entire planning cycle by executing `strategize_project.sh`, `define_requirements.sh`, and `plan_code_tasks.sh` in sequence.
*   **`strategize_project.sh`**: Takes high-level goals from `memory/project_goals.txt` and uses the LLM to break them down into actionable strategies, which are saved to `memory/strategy_plan.txt`.
*   **`define_requirements.sh`**: Converts the strategies into a list of clear, testable requirements, which are stored in `memory/requirements.md`.
*   **`plan_code_tasks.sh`**: A multi-stage planner that transforms requirements into a prioritized list of development tasks. It includes steps for revision and flagging ambiguous instructions.
*   **`task_manager.sh` / `enhanced_task_manager.sh`**: These scripts manage the task queue. They read a task, pass it to the LLM, enforce rules, and save the output. The `enhanced` version adds self-critique and output filtering.
*   **`run_task.sh`**: A simple script that executes `enhanced_task_manager.sh`.

#### PQL & Prompt Generation

*   **`parse_pql.sh`**: Your primary interface for interacting with `tasks.xml`. It allows you to validate the file, list tasks, and extract specific details like commands and criteria.
*   **`generate_prompt.sh`**: Assembles a structured prompt for the LLM based on a PQL task ID. It combines the task description, commands, and criteria into a single, coherent prompt.

#### Testing & Rule Enforcement

*   **`pql_test_and_consequence.sh` / `pql_test_and_reward.sh`**: These scripts manage the reward and consequence mechanism. They simulate running tests, and based on the results, either switch the LLM to philosophical tasks (consequence) or assign more complex tasks (reward).
*   **`rule_enforcer.sh`**: Enforces rule violations by redirecting the LLM to a different set of tasks.
*   **`validation_loop.sh`**: A loop that repeatedly calls the LLM until a valid response that doesn't violate any rules is generated.

#### Self-Reflection & Analysis

*   **`self_chat_loop.sh`**: Simulates a brainstorming session between different AI roles (e.g., "Researcher" and "Coder") to explore ideas and solutions.
*   **`memory_review.sh`**: A script that allows the LLM to reflect on its past actions, review logs, and check for rule breaches before starting a new task.
*   **`code_analysis.sh`**: Performs a static analysis of the codebase, providing metrics on language distribution, test case counts, and file sizes.

---

## ⚖️ AI Ethics and Bias Enhancement

QuantaPorto has undergone a significant enhancement of its ethics and bias detection system, introducing advanced multi-method bias detection, integrated pipeline processing, and comprehensive testing frameworks to ensure responsible AI deployment.

### Key Enhancements

- **Advanced Ethics and Bias Detection System**: A new standalone checker (`scripts/ethics_bias_checker.sh`), an enhanced task manager with integrated ethics checking (`scripts/enhanced_task_manager.sh`), and an advanced BDD test runner for ethics validation (`tests/bdd/enhanced_test_runner.sh`).
- **Comprehensive Bias Categories**: The system now detects a wide range of biases, including gender, racial, age, disability, socioeconomic, and religious biases, as well as intersectional bias and microaggressions.
- **Severity-Based Response System**: A scoring system classifies violations into Low, Medium, High, and Critical, with corresponding actions from logging to immediate timeouts.
- **Integrated Pipeline Processing**: The enhanced task manager provides real-time ethics checking, automatic bias mitigation, and configurable retry mechanisms.

For more details, please see the [full ethics enhancement documentation](docs/ETHICS_ENHANCEMENT_README.md).

---

## 📜 License

This project is licensed under the MIT License. See the `LICENSE` file for more details.
