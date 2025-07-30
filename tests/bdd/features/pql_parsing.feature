Feature: PQL Parsing and Command Processing

  Scenario: Valid PQL file parsing
    Given a valid PQL file with sample commands
    When I parse the PQL file
    Then the parsing should succeed
    And the commands should be extracted correctly
    And the criteria should be identified

  Scenario: Invalid PQL file handling
    Given an invalid PQL file with syntax errors
    When I parse the PQL file
    Then the parsing should fail
    And appropriate error messages should be generated
    And the validation should reference the schema

  Scenario: PQL to prompt conversion
    Given a parsed PQL command structure
    When I generate a prompt from the PQL
    Then a structured prompt should be created
    And the prompt should include all command elements
    And the prompt should be suitable for LLM processing

  Scenario: Schema validation against PQL
    Given a PQL file and corresponding XSD schema
    When I validate the PQL against the schema
    Then schema compliance should be verified
    And any schema violations should be reported
