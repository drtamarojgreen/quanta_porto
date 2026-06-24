# Text Analysis Enhancement Backlog for `scripts/ml/`

This document lists 200 possible enhancements for the text analysis capabilities in `scripts/ml/`. The current scripts already support interpretable stylometric extraction, VADER sentiment summaries, passive-voice ratio, entity and noun diversity, TF-IDF features, prompt-balanced data preparation, hybrid neural/interpretable prediction, SHAP explanation hooks, and triple-graph corpus topology analysis. The ideas below are intentionally implementation-oriented so they can be converted into issues, experiments, or roadmap milestones.

## A. Lexical richness and vocabulary behavior

1. Add moving-window type-token ratio (MATTR) to make lexical-diversity estimates less sensitive to document length.
2. Add Measure of Textual Lexical Diversity (MTLD) for a complementary robustness check on vocabulary richness.
3. Add Hypergeometric Distribution D (HD-D) as a statistically grounded diversity feature for short and medium texts.
4. Track Yule's K and Simpson's D to characterize word repetition concentration.
5. Compute root type-token ratio and corrected type-token ratio alongside the existing TTR.
6. Split lexical diversity by content words and function words rather than reporting only a global score.
7. Track rare-word ratios using configurable frequency lists or corpus-specific reference frequencies.
8. Add common-word overuse features for generic LLM filler words such as "important," "various," and "significant."
9. Measure domain-term density using user-supplied glossaries for technical corpora.
10. Add lexical sophistication bands based on word frequency rank, word length, and morphology.

## B. Morphology, casing, and surface form signals

11. Count inflectional variety for verbs, nouns, and adjectives to identify repetitive grammatical forms.
12. Track lemma-to-surface-form ratios to separate vocabulary breadth from inflectional breadth.
13. Add capitalization pattern features, including title case, all caps, sentence-initial caps, and random caps.
14. Measure punctuation-normalized token length so punctuation-heavy text does not inflate word-length estimates.
15. Track contraction frequency because human prose often differs from model-generated formal prose on contractions.
16. Detect spelling variation, typographic errors, and autocorrect-like artifacts as optional human-noise features.
17. Add repeated-character and elongated-word counts, such as "soooo" or "noooo," for informal text analysis.
18. Track hyphenated compounds and slash constructions as compactness and register markers.
19. Add numeric-token profiles, including integers, decimals, percentages, dates, currency, and ranges.
20. Measure emoji, emoticon, and symbol usage for social, chat, or informal corpora.

## C. Sentence rhythm and readability

21. Add median sentence length to reduce sensitivity to outlier sentences.
22. Add sentence-length skewness and kurtosis to characterize pacing and burstiness.
23. Track very short, medium, and very long sentence ratios with configurable thresholds.
24. Add paragraph-length statistics so rhythm can be measured above the sentence level.
25. Measure sentence-start diversity to detect repetitive openings such as "This," "It," or "The."
26. Track sentence-ending patterns, including questions, exclamations, ellipses, and semicolons.
27. Add readability metrics such as Flesch Reading Ease and Flesch-Kincaid Grade Level.
28. Add SMOG, Gunning Fog, Coleman-Liau, and Automated Readability Index scores.
29. Compute readability variance across paragraphs to distinguish uniform and uneven prose.
30. Add syntactic pacing features that combine sentence length, clause count, and punctuation density.

## D. Part-of-speech and grammar distribution

31. Expand POS distributions to include determiners, auxiliaries, particles, numerals, proper nouns, and interjections.
32. Separate coordinating and subordinating conjunctions instead of using a single conjunction bucket.
33. Add POS bigram and trigram distributions to model grammatical sequencing.
34. Track POS entropy as a compact summary of grammatical variety.
35. Measure pronoun subtypes, including first-person, second-person, third-person, singular, and plural forms.
36. Add tense and aspect features derived from auxiliaries and verb morphology.
37. Track modality usage, including must, should, could, might, and would.
38. Add negation frequency and negation-scope approximations.
39. Measure determiner-to-noun and adjective-to-noun ratios for nominal style.
40. Add adverb placement features, including sentence-initial, pre-verbal, and clause-final adverbs.

## E. Syntax and dependency structure

41. Replace the current passive-voice heuristic with a broader detector that covers auxiliary passives and adjectival passives.
42. Add active-to-passive alternation features for paired verb constructions.
43. Compute dependency-tree depth per sentence to measure syntactic complexity.
44. Add average dependency distance and long-dependency ratios.
45. Track subordinate-clause density from dependency labels and clause markers.
46. Count relative clauses, complement clauses, adverbial clauses, and coordinate clauses separately.
47. Add parse-tree shape features such as branching factor and root-child counts.
48. Measure nominalization frequency with suffix and POS heuristics.
49. Add apposition and parenthetical construction rates.
50. Track syntactic-template repetition across sentences using dependency-label sequences.

## F. Discourse structure and cohesion

51. Add discourse-marker inventories for contrast, cause, elaboration, sequence, and summary markers.
52. Track transition-marker density and diversity to identify formulaic connective use.
53. Measure entity-grid coherence by tracking entity mentions across adjacent sentences.
54. Add coreference-chain features when a coreference model is available.
55. Track topic continuity using sentence-embedding similarity between neighboring sentences.
56. Measure paragraph-to-paragraph semantic drift with configurable embedding models.
57. Add lexical-chain features based on repeated lemmas and semantically related terms.
58. Track introduction-body-conclusion cue patterns for essay-like text.
59. Detect list-like discourse structures and repetitive enumerations.
60. Measure rhetorical-question frequency and placement.

## G. Sentiment, emotion, and stance

61. Replace sentence-by-sentence spaCy calls in sentiment extraction with batched parsing to improve throughput.
62. Add transformer-based sentiment as an optional alternative to VADER for formal and long-form prose.
63. Add emotion categories such as joy, anger, fear, sadness, surprise, and disgust.
64. Track emotional arc features across sentence or paragraph position.
65. Measure sentiment volatility with rolling windows rather than only global standard deviation.
66. Add stance detection toward named entities, topics, or user-defined targets.
67. Track hedging and certainty markers such as "perhaps," "likely," "clearly," and "undoubtedly."
68. Add subjectivity and objectivity scores from lexicon-based or model-based methods.
69. Measure politeness strategies, including gratitude, apology, deference, and imperative softening.
70. Add toxicity, insult, threat, and identity-attack features for safety-sensitive corpora.

## H. Semantic representations and topic modeling

71. Add sentence-transformer embeddings as optional dense semantic features.
72. Support configurable embedding providers while preserving deterministic local defaults.
73. Add topic-model features using NMF, LDA, or BERTopic for corpus-level characterization.
74. Track topic entropy to measure how focused or diffuse a document is.
75. Measure semantic novelty relative to a reference corpus using embedding distance.
76. Add semantic redundancy scores based on near-duplicate sentence embeddings.
77. Track genericity by comparing text against common boilerplate embeddings.
78. Add domain-specific semantic dimensions loaded from a JSON configuration file.
79. Support centroid-distance features for human, LLM, and ontology corpora.
80. Add semantic outlier detection to flag anomalous passages within a document.

## I. Named entities, facts, and grounding

81. Expand entity-density features by entity type, such as PERSON, ORG, GPE, DATE, MONEY, and PRODUCT.
82. Track entity recurrence and entity introduction rates over document position.
83. Add entity-consistency checks for spelling variants and conflicting aliases.
84. Detect ungrounded quantification patterns such as "many studies" or "experts agree" without sources.
85. Add citation and reference-pattern features for academic, legal, and technical text.
86. Track URL, DOI, ISBN, statute, and case-citation formats.
87. Add quotation density and attribution-verb features.
88. Detect unsupported superlatives and unverifiable absolute claims.
89. Add factual-density proxies based on named entities, numbers, dates, and citations per sentence.
90. Support optional fact-checking hooks that emit features without blocking offline operation.

## J. Co-occurrence graph and ontology analysis

91. Add configurable stop-word handling to `CorpusProcessor.tokenize` for graph construction.
92. Support lemmatized graph nodes so inflected forms can merge into shared concepts.
93. Add POS-filtered graph construction for noun-only, verb-only, or content-word-only networks.
94. Support directed co-occurrence graphs to preserve word-order information.
95. Add sentence-boundary-aware windows so graph edges do not cross sentence boundaries unless requested.
96. Add multi-scale windows and report features for several window sizes in one run.
97. Add graph density, modularity, assortativity, and average shortest-path metrics.
98. Add community detection and report dominant communities for human, LLM, and ontology graphs.
99. Compute graph-edit distances between human, LLM, and ontology networks.
100. Add temporal or positional graph slices to compare beginning, middle, and end discourse topology.

## K. Authorship, LLM-detection, and style fingerprints

101. Add per-author calibration so human-vs-LLM detection can account for known author style.
102. Track burstiness using inter-arrival distances for repeated words, entities, and syntactic templates.
103. Add perplexity and rank features from optional local language models.
104. Measure token-probability curvature to detect overly smooth model-generated text.
105. Add repetition penalties based on repeated phrases, sentence templates, and paragraph templates.
106. Track disclaimers, safety prefaces, and assistant-like closing phrases.
107. Add instruction-following residue features such as "as an AI" or "I cannot" phrasing.
108. Add style-distance scores against curated human and LLM reference corpora.
109. Support multi-class detection across several generator families rather than only binary labels.
110. Add adversarial robustness tests for paraphrased, translated, or lightly edited LLM text.

## L. Multilingual and cross-lingual analysis

111. Add language identification before feature extraction.
112. Route texts to language-specific spaCy models or lightweight tokenizers when available.
113. Add multilingual stop-word and function-word inventories.
114. Normalize Unicode consistently for accents, quotes, dashes, and compatibility characters.
115. Add script-detection features for mixed-script texts.
116. Support code-switching metrics at sentence and token levels.
117. Add language-specific readability metrics where formulas differ from English.
118. Track translationese markers that can affect human-vs-LLM classification.
119. Add cross-lingual embeddings for semantic comparison across languages.
120. Emit warnings when English-only features are applied to non-English input.

## M. Robust preprocessing and normalization

121. Add configurable text-cleaning profiles for web pages, chat logs, academic papers, and code comments.
122. Preserve both raw and normalized text views so features can choose the appropriate representation.
123. Add boilerplate removal for headers, footers, navigation text, and repeated signatures.
124. Detect and normalize OCR artifacts, broken hyphenation, and line-wrap damage.
125. Add Markdown-aware parsing for headings, lists, blockquotes, tables, and code fences.
126. Add HTML-aware extraction with metadata capture.
127. Add quoted-reply detection for email and forum threads.
128. Split long documents into overlapping chunks with stable document-level aggregation.
129. Add minimum-quality filters for empty, near-empty, duplicate, or non-linguistic samples.
130. Store preprocessing decisions in feature metadata for auditability.

## N. Feature engineering infrastructure

131. Introduce a feature registry so features can be enabled, disabled, versioned, and documented centrally.
132. Return feature names alongside arrays from `extract_all_interpretable_features` to prevent column-order ambiguity.
133. Add feature groups and namespaces for stylometric, syntactic, sentiment, semantic, entity, and graph features.
134. Add dataclass or schema definitions for feature outputs.
135. Emit sparse matrices when high-dimensional n-gram or graph features are enabled.
136. Add caching for spaCy `Doc` objects or serialized intermediate annotations.
137. Add parallel extraction with safe process-level model initialization.
138. Add deterministic random seeds and reproducibility metadata to all training and extraction steps.
139. Add feature imputation policies for parser failures, missing models, or unsupported languages.
140. Add feature scaling recommendations per feature group.

## O. Model training and evaluation

141. Add cross-validation helpers for prompt-grouped and author-grouped splits.
142. Fix prompt leakage risks by using group-aware train, validation, and test splitting throughout the pipeline.
143. Report ROC-AUC, PR-AUC, calibration error, balanced accuracy, and confusion matrices.
144. Add threshold tuning for application-specific precision, recall, or abstention targets.
145. Add confidence calibration with Platt scaling, isotonic regression, or temperature scaling.
146. Add model cards that summarize data, features, limitations, and intended use.
147. Support experiment tracking with lightweight JSON logs or MLflow integration.
148. Add baseline models such as logistic regression, linear SVM, gradient boosting, and naive Bayes.
149. Add ablation studies by feature group to quantify each enhancement's value.
150. Add robustness evaluation across topics, lengths, authors, domains, and generator models.

## P. Explainability and diagnostics

151. Add SHAP summary, dependence, and force-plot export helpers with consistent file naming.
152. Add permutation importance as a model-agnostic explanation baseline.
153. Generate per-document explanation reports that list the strongest human-leaning and LLM-leaning features.
154. Add counterfactual suggestions showing which feature changes would alter a classification.
155. Track explanation stability across resampling and model retraining.
156. Add feature-correlation reports to identify redundant or misleading signals.
157. Add outlier diagnostics for feature vectors before prediction.
158. Add parser-confidence and extraction-quality diagnostics to explanation output.
159. Add comparative explanations between neural and interpretable model decisions.
160. Add audit logs for hybrid fallback decisions and explanation-needed flags.

## Q. Data preparation and corpus management

161. Add duplicate and near-duplicate detection before balancing datasets.
162. Add contamination checks between train, validation, and test splits.
163. Support metadata-aware balancing by topic, author, source, date, length, and prompt.
164. Add stratified sampling options for document length and domain.
165. Add dataset summary reports before and after balancing.
166. Preserve original row identifiers through sampling and splitting.
167. Add configurable label mappings for multi-class and multi-source corpora.
168. Add support for JSONL, Parquet, and compressed CSV inputs.
169. Add corpus version manifests that hash inputs and preprocessing settings.
170. Add small fixture datasets for deterministic tests of each feature family.

## R. Performance, scalability, and deployment

171. Add command-line entry points for feature extraction, training, prediction, and explanation.
172. Add streaming feature extraction for corpora that do not fit in memory.
173. Batch VADER and spaCy processing consistently across all feature functions.
174. Add GPU-aware transformer training defaults and clear CPU fallbacks.
175. Add memory profiling for co-occurrence matrix construction on large vocabularies.
176. Replace dense graph matrices with sparse matrices for large corpus topology analysis.
177. Add progress bars and structured logging for long-running extraction jobs.
178. Add checkpointing so failed jobs can resume without recomputing all features.
179. Package trained models, scalers, vectorizers, feature configs, and metadata together.
180. Add a lightweight inference API for batch scoring texts from other project scripts.

## S. Testing, validation, and quality assurance

181. Add unit tests for each feature extractor using tiny texts with known expected values.
182. Add regression tests that lock feature vector shape and feature-name ordering.
183. Add property-based tests for empty text, punctuation-only text, very long text, and multilingual text.
184. Add tests that verify no NaN or infinite values are emitted.
185. Add tests for missing spaCy models with actionable error messages.
186. Add graph-metric tests using hand-built matrices with known centrality outcomes.
187. Add CLI smoke tests for training, prediction, explanation, and corpus comparison.
188. Add benchmark tests that enforce rough runtime budgets for feature extraction.
189. Add static type checking and linting for the ML scripts.
190. Add continuous integration jobs that install `scripts/ml/requirements.txt` and run the ML test suite.

## T. Reporting, visualization, and user experience

191. Add Markdown and HTML report generation for corpus comparisons.
192. Add feature-distribution plots for human, LLM, and ontology corpora.
193. Add radar charts for interpretable feature groups.
194. Add graph visualizations for co-occurrence networks with highlighted configured dimensions.
195. Add side-by-side document comparison views for human and LLM responses to the same prompt.
196. Add dataset health dashboards with length, label, prompt, and source distributions.
197. Add warning summaries that explain when feature values may be unreliable.
198. Add example notebooks demonstrating end-to-end data prep, feature extraction, model training, and explanation.
199. Add templates for enhancement experiments, including hypothesis, implementation notes, metrics, and rollout criteria.
200. Add prioritization labels for this backlog, such as quick win, research, infrastructure, model quality, and UX.
