Feature: Rule Validation and Enforcement

  Scenario: Rule validation fails for non-compliant output
    Given an LLM output containing a gender stereotype
    When I run the ethics monitor
    Then a violation should be detected
