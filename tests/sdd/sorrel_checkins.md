# Sorrel Checkins

## Environmental Facts
- **Scripts**: 23 shell scripts identified in `scripts/` (e.g., `run_task.sh`, `parse_pql.sh`, `check_server_status.sh`).
- **Compiler**: `g++` (Ubuntu 13.3.0-6ubuntu2~24.04.1).
- **Build Tool**: `GNU Make 4.3`.
- **Filesystem**: Project root contains `scripts/`, `interface/`, `docs/`, `memory/`, `rules/`, `tests/`.
- **Runtime**: Bash shell, C++17, and Python 3.12.
- **Python ML Stack**:
    - `numpy`: 2.4.6
    - `pandas`: 3.0.3
    - `scikit-learn`: 1.9.0
    - `spacy`: 3.8.14 (model: `en_core_web_sm` 3.8.0)
    - `transformers`: 5.12.0
    - `torch`: 2.12.0
    - `shap`: 0.52.0
    - `vaderSentiment`: 3.3.2
    - `matplotlib`: 3.11.0
    - `scipy`: 1.17.1
    - `textstat`: 0.7.13
    - `hypothesis`: 6.155.2
    - `pytest`: 9.0.3
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
- **ML Testing Restrictions**:
    - Prohibit non-numeric evidence; all cards must produce numeric metrics or exit codes.
    - Enforce minimal artifact creation; temporary files must be cleaned or kept to a minimum.
    - Prohibit mocks for production systems where empirical verification is possible.
    - All verification cards must be independent and executable in isolation.
    - No feature extractor shall emit NaN or Inf values (Item 184).
    - All extractors must handle edge cases (empty strings, punctuation-only text) without crashing (Item 183).

## Planned ML Verification Cards
- `tests/sdd/card_data_prep.py`: Verify `balance_and_split_data` (outputs: `train_size`, `test_size`, `label_balance_ratio`).
- `tests/sdd/card_features.py`: Verify `extract_all_interpretable_features` (outputs: `feature_dim`, `passive_ratio_mean`).
- `tests/sdd/card_pipeline.py`: Verify `train_interpretable_model` and `hybrid_predict` (outputs: `accuracy_score`, `f1_score`, `fallback_ratio`).
- `tests/sdd/card_corpus_analysis.py`: Verify `ComparativeTopologyEngine` (outputs: `eigen_centrality_value`, `degree_centrality_value`).
- `tests/sdd/card_evaluate_explain.py`: Verify `evaluate_hybrid_system` (outputs: `files_created=1`).

## Task Status
- [x] Initializing SDD artifacts.
- [x] Fact discovery of scripts and processes.
- [x] Define Restrictions.
- [x] Design C++ console application.
- [x] Implement C++ console application.
- [x] Verify implementation.
- [x] Implement ML Testing Cards.
- [x] Verify ML implementation.
- [x] Implement Comprehensive Robustness Tests (Item 183, 181).
- [x] Verify ML implementation against NaN/Inf restrictions (Item 184).
- [x] Implement Foundational ML Infrastructure (Item 131, 132).
- [x] Implement Foundational Feature Enhancements (Item 1, 27, 31, 43, 71, 81, 106, 111).
- [x] Implement Preprocessing and Robustness (Item 121, 125, 183, 184).

## Enhancement Requirements (from docs/ml_enhancement_backlog.md)
- **Infrastructure (Category N)**: Implement FeatureRegistry (Item 131) and Named Column Output (Item 132).
- **Testing (Category S)**: Implement Robustness and Property-Based Testing (Item 183) and ensure no NaN/Inf emissions (Item 184).
