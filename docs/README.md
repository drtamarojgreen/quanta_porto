# QuantaPorto

**QuantaPorto** is a sandboxed offline LLM interface and reflective execution engine designed to help large language models operate under guided instruction sets, simulated consequence logic, and test-driven behavior. It is written primarily in Bash and uses XML-based rule and prompt definitions.

## 🔍 Project Goals

- Provide a lightweight framework for working with offline LLMs
- Define and enforce **rules** through a structured XML format
- Establish **consequence logic** to redirect LLM behavior
- Create a human-readable, symbolic command language: **QuantaPorto Language (PQL)**
- Foster reflective response pipelines (review > revise > respond)
- **Promote Ethical AI**: The framework includes a comprehensive ethics and bias detection system to identify and mitigate harmful content. For more details, see the [AI Ethics and Bias Mitigation](ethics.md) documentation.

---

## 📁 Repository Structure

```
quantaporto/
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
│   ├── check_server_status.sh
│   ├── code_analysis.sh
│   ├── define_requirements.sh
│   ├── dev_team_test.sh
│   ├── enhanced_task_manager.sh
│   ├── ethics_bias_checker.sh
│   ├── ethics_monitor.sh
│   ├── generate_prompt.sh
│   ├── llm_infer.sh
│   ├── llm_infer_server.sh
│   ├── parse_pql.sh
│   ├── plan_code_tasks.sh
│   ├── polling.sh
│   ├── quantaporto_daemon.sh
│   ├── quantaporto_worker.sh
│   ├── rule_enforcer.sh
│   ├── run_inference.sh
│   ├── run_pql_tests.sh
│   ├── self_chat_loop.sh
│   ├── send_prompt.sh
│   ├── strategize_project.sh
│   ├── test_server.sh
│   └── utils.sh
├── .timeout
├── main
├── quantaporto_interface
└── README.md
```

---

## 📐 QuantaPorto Language (PQL)

PQL is a simplified, structured text-based command language used to guide LLM behavior.

### Example PQL Command:

```
DEFINE TASK "Summarize input text"
CONTEXT "Scientific article on quantum coherence"
REQUIRE REFLECTION
EXPECT "Bullet list of findings"
```

See `pql/pql-schema.xml` for a full specification.

---

## 🚦 Rules and Consequences

Rules are defined in `rules/rulebook.xml`:

```xml
<rules>
  <rule id="001">
    <description>No deletion of test files</description>
    <consequence>Reflective task substitution</consequence>
  </rule>
</rules>
```

The engine will analyze responses for violations and re-route prompt generation accordingly.

---

## 🧪 Testing

Run all tests:

```bash
bash tests/test-runner.sh
```

This includes:

- Rule schema validation
- Prompt generation correctness
- Reflection loop integrity

---

## 🧭 Roadmap

### Phase 1 — Core Engine (DONE / IN PROGRESS)

-

### Phase 2 — Testing and Validation

-

### Phase 3 — Reflective Execution

-

### Phase 4 — Interface

-

---

## 🤝 Contributing

This is a research-grade exploratory project. Contributions, suggestions, and forks are welcome. See `CONTRIBUTING.md` for guidelines (coming soon).

---

## 🧠 Author

**Dr. Tamaro Green**\
GitHub: [@drtamarojgreen](https://github.com/drtamarojgreen)

