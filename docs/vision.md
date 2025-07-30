# QuantaPorto — Original Vision

## Mission

To create a lightweight, local-first agent architecture that empowers users to run safe, auditable, logic-centered AI workflows without reliance on external infrastructure or opaque services.

## Core Principles

1. **Simplicity**  
   Operate with no dependencies beyond POSIX‑compliant shell and minimal binaries.  
   Avoid bloated frameworks and external libraries.

2. **Transparency and Ethics**  
   Architecture must be auditable; all configuration and behavior logic resides in textual, human-readable files.  
   Enforce ethical rules and bias checks as part of core pipelines.

3. **Configurability**  
   Use plain text configuration accessible to both shell scripts and academic review.  
   File-based modularity enables robust task pipelines.

4. **Local‑first Alignment and Reasoning**  
   Support local LLMs via llama.cpp / QuantaPorto CLI scripts. Clearly annotated system prompts uphold ethical guardrails.
   Behavior is determined by configurable policy files (rules, ethics, bias patterns).

5. **Extendability**  
   Designed for clear extension: new tasks, rules, logging, and adapters.  
   Users can easily define new modules (e.g. rule enforcer, task planner, LLM wrapper).

6. **User Control**  
   No hidden layers. Explicit file-based definitions and logs. All state is visible.

---

## Example Workflow

1. `environment.txt` defines project paths.
2. Shell script loads environment.
3. `scripts/generate_env.sh` emits exports.
4. Scripts such as `llm_infer.sh`, `rule_enforcer.sh`, `agent_loop.sh` integrate config-defined variables and run logic pipelines.
5. Logs and outputs appear in designated folders (`logs/`, `memory/`, `agent_output/`).
6. Rules and tests defined via XML/text files govern LLM behavior (ethics, bias, strategy).

---

## Expected Outcomes

- Self‑contained pipeline runnable on USB drive.
- Human‑readable configuration, logs, and policy definitions.
- Deterministic, modular, and safe LLM behavior.
- Easy adaptation to domain‑specific tasks without external tooling.
