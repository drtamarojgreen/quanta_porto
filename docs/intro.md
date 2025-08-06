# QuantaPorto

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

```
.
├── docs/               # Project documentation
├── interface/          # C++ interface for LLM interaction
├── prompts/            # System and user prompt templates
├── rules/              # PQL and ethics rule definitions (XML, XSD)
├── scripts/            # Core automation and task execution scripts
├── tests/              # BDD and unit tests
│   └── bdd/
│       ├── features/
│       └── step_definitions.sh
├── environment.txt     # Main configuration file
└── README.md
```
