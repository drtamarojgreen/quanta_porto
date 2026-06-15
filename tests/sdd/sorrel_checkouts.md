# Sorrel Checkouts

## Completed Work
- **Porto Manager Design**: Completed in `docs/porto_manager_design.md`.
- **Porto Manager Implementation**: Completed in `interface/porto_manager.cpp`.
- **Configuration Integration**: Integrated with `Config.h`/`Config.cpp` and `environment.txt`.
- **Build System**: Created `Makefile` for automated compilation.
- **Verification**:
    - Verified script discovery and listing.
    - Verified script execution with arguments.
    - Verified logging to `logs/quantaporto.log`.
    - Verified exit code reporting using `WEXITSTATUS`.
    - Verified command injection mitigation via input sanitization.

## ML Categorical Classification
- **Completed Work**:
    - Enhanced `scripts/ml/corpus_analysis.py` with `WordCategorizer` for cross-corpus leaning and dimension assignment.
    - Updated `scripts/ml/features.py` to include `HumanLeaningRatio`, `LLMLeaningRatio`, and `TopDimRatio` features.
    - Created `scripts/ml/dimensions.json` for grounded dimension definitions.
    - Implemented `tests/ml/test_categorical_analysis.py` for automated verification.
- **Completed Features**:
    - Lexical: MATTR (A.1), MTLD (A.2), HD-D (A.3), Yule's K (A.4), Root/Corrected TTR (A.5), Content/Func TTR (A.6), Filler Ratio (A.8).
    - Morphology: Capitalization (B.13), Contractions (B.15), Inflectional Variety (B.11), Lemma Ratio (B.12), Typos (B.16), Elongated (B.17), Numeric (B.19).
    - Rhythm & Readability: Median/Skew/Kurt Sentence length (C.21, 22), SMOG/ARI/Gunning Fog (C.28), Question Ratio (C.26).
    - POS/Grammar: Expanded tags (D.31), POS Entropy (D.34), Pronoun Subtypes (D.35), Negation (D.38).
    - Syntax: Tree Depth/Distance (E.43, 44), Subordinate Ratio (E.45).
    - Discourse/Facts: Markers/Transitions (F.51, 52), Detailed Entity Ratios (I.81), Ungrounded Phrasing (I.84), Factual Density (I.89).
    - Fingerprint: Burstiness (K.102), Bigram Repetition (K.105), LLM Residue/Safety (K.106, 107).
- **Verification**:
    - Verified word leaning classification using mock corpuses: `tests/ml/test_words.csv` generated with expected `Human-leaning` and `LLM-leaning` labels.
    - Verified integration with ML pipeline: `test_pipeline.py` executes successfully with 85 total features.
    - Verified individual batches via `tests/ml/test_batch_*.py`.
    - Verified repository hygiene: No `__pycache__` or temporary artifacts committed.
