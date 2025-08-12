# PrismQuanta Integration Vision

This document provides a unified vision for integrating the various `quanta_*` repositories into a cohesive, autonomous system capable of automated development, maintenance, and knowledge harvesting.

---

## Repository Summaries

Each repository represents a specialized cognitive or functional module within the PrismQuanta ecosystem, modeled metaphorically on a biological nervous system.

- **QuantaAlarma**: Monitors LLM agent outputs for risks, providing analysis, scoring, and alerts to ensure safe and compliant operation.
- **QuantaCerebra**: (Assumed Role) The high-level orchestrator, responsible for strategic planning, goal decomposition, and initiating system-wide objectives.
- **QuantaCogno**: Provides specialized knowledge and tools, acting as an interface to complex, domain-specific APIs (e.g., genomics, financial data).
- **QuantaCortex**: (From Vision Doc) A visualization layer for displaying system status, documentation, and agent activity, providing a transparent window into the system's mind.
- **QuantaDorsa**: (Assumed Role) Manages the "how" and "where" of task execution, potentially mapping abstract goals to concrete workflows and tool usage.
- **QuantaEthos**: Acts as the ethical filter, evaluating signals and agent actions against a defined moral and safety framework before execution.
- **QuantaGlia**: (From Vision Doc) The knowledge management system, responsible for pruning, caching, summarizing, and committing information to long-term memory.
- **QuantaLista**: (Assumed Role) A task management or queuing component, responsible for tracking, prioritizing, and managing work items for agents.
- **QuantaMemora**: (Assumed Role) The long-term memory store for the agent ecosystem, providing persistence for learned knowledge and experiences.
- **QuantaOccipita**: (From Vision Doc) A scaffolding module for bootstrapping new logic, agents, or project structures, enabling automated code generation.
- **QuantaPorto**: A sandboxed execution engine for running LLM-driven tasks with rule-based guidance, consequence logic, and reflective loops.
- **QuantaPulsa**: (Assumed Role) The system's heartbeat, likely a scheduler or health monitoring daemon that ensures all components are operational.
- **QuantaRetina**: (Assumed Role) The primary input/perception module, responsible for ingesting and parsing raw data from various sources (e.g., file systems, APIs, git repositories).
- **QuantaSensa**: The autonomous workflow agent; the "hands" of the system that executes the tasks defined by the planning modules.
- **QuantaSerene**: (Assumed Role) A state management or system stability module, ensuring calm and orderly operations, possibly by managing resource contention or resolving internal conflicts.
- **QuantaSynapse**: The central message bus and nervous system, responsible for routing all signals and data packets between the various Quanta components.
- **QuantaTissu**: (Assumed Role) Manages the "fabric" and structure of the system's knowledge base or internal data representations, ensuring consistency and integrity.

---

## High-Level Integration Plan

The integration will proceed in phases, building from a core communication and execution loop to a fully autonomous, self-maintaining system.

### Phase 1: Foundational Integration (The Nervous System)

**Goal**: Establish the core communication, ethical oversight, and execution loop.

1.  **Implement `QuantaSynapse`**: Implement `QuantaSynapse` as an active communication orchestrator. It will consist of two parts: (1) a lightweight, in-memory pub/sub library for inter-process communication, and (2) a configuration-driven tool that reads a central network topology map and generates the necessary subscription and publishing code within each target repository. This automates the creation of the "nervous system" and allows communication pathways to be reconfigured centrally.
2.  **Define Initial Network Topology**: Configure the `QuantaSynapse` topology map to establish the primary cognitive pathway:
    -   Define `QuantaSensa` as a publisher of `ActionIntention` signals.
    -   Define `QuantaEthos` as a subscriber to `ActionIntention` and a publisher of `ActionGo/NoGo` signals.
    -   Define `QuantaPorto` as a subscriber to `ActionGo` and a publisher of `TaskResult` signals.
    -   Run the `QuantaSynapse` generation tool to create the connection logic in these three repositories.
3.  **Establish Basic Workflow**: A user can issue a simple command, which is passed through the ethical check, executed securely, and the result is returned, demonstrating the basic cognitive pathway.

### Phase 2: Knowledge & Memory Integration (The Brain)

**Goal**: Enable the system to perceive, learn, remember, and utilize knowledge.

1.  **Build `QuantaMemora`**: Implement a persistent long-term memory solution using structured CSV files to store learned information. The implementation should follow the model established in `quanta_porto` for managing its `rules/ethics_rules.csv` file.
2.  **Integrate Perception (`QuantaRetina`)**: `QuantaRetina` watches designated sources (e.g., git repositories, documentation folders) and publishes `RawData` signals containing new or changed information.
3.  **Integrate Knowledge Processing (`QuantaGlia`)**: `QuantaGlia` subscribes to `RawData` and `TaskResult` signals. It processes, summarizes, and transforms this information into structured knowledge chunks, which it then commits to `QuantaMemora`.
4.  **Integrate Specialized Knowledge (`QuantaCogno`)**: `QuantaSensa` can query `QuantaCogno` via `QuantaSynapse` when a task requires a specialized tool (e.g., the mental health genomics API), allowing it to leverage complex external knowledge.

### Phase 3: Self-Maintenance & Automation (The Autonomous System)

**Goal**: Create a self-improving system that can manage its own development, maintenance, and planning.

1.  **High-Level Planning (`QuantaCerebra`)**: `QuantaCerebra` observes the system's state (e.g., from logs or `QuantaAlarma` reports) and generates high-level goals like "Improve test coverage in QuantaPorto". It publishes these as `StrategicObjective` signals.
2.  **Task Decomposition (`QuantaLista`)**: `QuantaLista` subscribes to `StrategicObjective` signals, breaks them down into concrete, actionable tasks (e.g., "1. Analyze current test coverage. 2. Identify untested scripts. 3. Write new BDD tests."), and publishes them to a task queue for `QuantaSensa`.
3.  **Automated Code Generation (`QuantaOccipita`)**: When a task involves creating a new module or script, `QuantaSensa` can invoke `QuantaOccipita` to generate the initial boilerplate code, which it then refines and implements.
4.  **Monitoring & Feedback (`QuantaAlarma`)**: `QuantaAlarma` continuously monitors the outputs of `QuantaSensa` as it performs development and maintenance tasks. It provides a crucial safety and quality feedback loop by publishing `Alert` signals that `QuantaCerebra` can use for future planning and self-correction.

### Phase 4: Full System Awareness & Visualization (The Interface)

**Goal**: Provide human operators with a clear, real-time view into the system's operations and cognitive processes.

1.  **System Heartbeat (`QuantaPulsa`)**: Implement `QuantaPulsa` to monitor the health, message throughput, and status of all components, publishing regular `SystemStatus` signals.
2.  **Visualization Dashboard (`QuantaCortex`)**: `QuantaCortex` subscribes to all major signals (`ActionIntention`, `TaskResult`, `Alert`, `SystemStatus`, etc.) and renders a real-time dashboard. This interface will visualize the entire cognitive architecture at work, fulfilling the project's vision of a system that is "as transparent as it is autonomous."