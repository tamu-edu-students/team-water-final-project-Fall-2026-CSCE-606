Feature: Inventory Management
  As a roommate
  I want to track household supplies
  So that we don't run out of necessities

  Background:
    Given I am a member of "Apartment 101"

  Scenario: Adding item to inventory
    When I click "Add Supply"
    And I enter "Paper Towels" with quantity "5"
    And I set low stock threshold to "2"
    And I click "Save"
    Then "Paper Towels: 5" appears in inventory
    And no low stock alert is shown

  Scenario: Low stock alert
    Given "Paper Towels" has threshold "2"
    When quantity drops to "1"
    Then item appears in shopping list
    And dashboard shows low stock alert

  Scenario: Marking item as purchased
    Given "Paper Towels" is on shopping list
    When I mark as purchased with quantity "6"
    Then inventory updates to "7"
    And purchase history shows my contribution

  Scenario: Invalid quantity update
    When I try to update quantity to "-3"
    Then I see "Quantity must be non-negative"
