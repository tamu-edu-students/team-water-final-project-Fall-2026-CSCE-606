Feature: Chore Management
  As a roommate
  I want to create and track chores
  So that responsibilities are distributed fairly

  Background:
    Given I am a member of "Apartment 101"

  Scenario: Creating a recurring chore
    When I click "Add Chore"
    And I enter title "Clean Kitchen"
    And I set frequency to "Weekly"
    And I assign to "John"
    And I click "Create Chore"
    Then "Clean Kitchen" appears in chore list
    And it shows as due weekly

  Scenario: Completing a chore
    Given "Clean Kitchen" is assigned to me
    When I mark the chore as complete
    Then the chore shows completed status
    And completion history is updated
    And next occurrence is scheduled

  Scenario: Overdue chore notification
    Given a chore is 2 days overdue
    When I view the dashboard
    Then the chore appears highlighted in red
    And I see "2 days overdue"

  Scenario: Chore rotation
    Given "Take Out Trash" rotates between members
    When the chore is completed by "John"
    Then next assignment goes to "Jane"
