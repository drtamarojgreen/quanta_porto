Feature: Machine Learning Pipeline Testing
  As a systems architect
  I want to verify the ML pipeline components
  To ensure they conform to structural and empirical constraints

  Scenario: Data Preparation Matching and Splitting
    Given a set of human and LLM texts with matching prompts
    When the balance_and_split_data function is executed
    Then the resulting datasets should be balanced by label
    And there should be no prompt leakage between train and test sets

  Scenario: Feature Extraction Accuracy
    Given a set of sample texts
    When interpretable features are extracted
    Then the feature vector dimension should be 24
    And the TTR value should be mathematically valid for the given text

  Scenario: Hybrid Model Prediction
    Given a trained interpretable model and mock neural probabilities
    When the hybrid_predict function is called
    Then the system should correctly fall back to the interpretable model when neural uncertainty is high

  Scenario: Corpus Topology Analysis
    Given a human and LLM corpus and a configuration
    When the ComparativeTopologyEngine analyzes the corpora
    Then it should produce valid numeric centrality and connectivity metrics
