Feature: Expense Management
  As a roommate
  I want to track and split shared expenses
  So that household finances remain transparent and fair

  Background:
    Given a household named "Apartment 101" exists
    And I am logged in as "alice@example.com"
    And I am a member of "Apartment 101"

  Scenario: Create expense with equal split
    Given I am logged in as "bob@example.com"
    And I am a member of "Apartment 101"
    When I create an expense "Groceries" for $90.00
    Then the expense "Groceries" was created successfully
    And each member should owe $45.00

  Scenario: Create expense with custom split
    Given I am logged in as "bob@example.com"
    And I am a member of "Apartment 101"
    When I create an expense "Utilities" for $100.00 with custom split
    Then I should see "Expense created successfully"
    And the expense should be split correctly

  Scenario: Mark payment as complete
    Given I am logged in as "bob@example.com"
    And I am a member of "Apartment 101"
    And I create an expense "Internet" for $60.00
    When I mark my portion as paid for "Internet"
    Then I should see "Payment marked as complete"
    And my payment status should be "paid" for "Internet"

  Scenario: Reject negative expense amount
    When I try to create an expense with negative amount
    Then I should see "Amount must be positive"

  Scenario: Require login to create expense
    Given I am not logged in
    When I try to create an expense "Test" for $50.00
    Then I should be redirected to the login page

  Scenario: Calculate precise decimal splits
    Given I am logged in as "bob@example.com"
    And I am a member of "Apartment 101"
    When I create an expense "Pizza" for $33.33
    Then the expense should be split correctly
    And I should owe $16.67 for "Pizza"