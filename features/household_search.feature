Feature: Find a household before joining
  As a roommate, I want to search for a household by name and join with its
  invitation code so that I can find the right home without losing access control.

  Background:
    Given a household named "Water House" exists
    And I sign in through the household search interface

  Scenario: Search, select, and join a household
    When I search for households named "wAtEr"
    And I select the household search result "Water House"
    And I submit the selected household's invitation code
    Then my search account belongs to "Water House"

  Scenario: No matching households
    When I search for households named "Missing Home"
    Then the household search page says "No households found"

  Scenario: An incorrect code preserves the selection
    When I search for households named "Water"
    And I select the household search result "Water House"
    And I enter an incorrect code for the selected household
    Then the household search page says "Invalid invitation code."
    And the household search page says "Water House"
    And my search account has not joined any household
