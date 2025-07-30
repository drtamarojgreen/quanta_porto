Feature: Priority-Based Task Scheduling

  Scenario: Task priority loading from config
    Given a priorities.txt file with task priorities
    When I load the priority configuration
    Then the priorities should be parsed correctly
    And a priority map should be created
    And higher numbers should indicate higher priority

  Scenario: Task selection based on priority
    Given multiple tasks with different priorities
    When I select the next task to execute
    Then the highest priority task should be selected
    And lower priority tasks should remain queued

  Scenario: Priority-based prompt assignment
    Given tasks with assigned priorities
    And corresponding prompt templates
    When I assign prompts based on priority
    Then the highest priority task should get the active prompt
    And the prompt should be loaded into input_prompt.txt

  Scenario: Dynamic priority adjustment
    Given a running task with initial priority
    When task conditions change requiring priority adjustment
    Then the priority should be updated dynamically
    And the task queue should be reordered accordingly
