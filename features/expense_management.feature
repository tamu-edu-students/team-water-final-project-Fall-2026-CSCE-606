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
    Then the expense "Utilities" was created successfully
    And the expense should be split correctly

  Scenario: Split an expense between selected members only
    Given I am logged in as "bob@example.com"
    And I am a member of "Apartment 101"
    When I create an expense "Dinner" for $90.00 split between "bob@example.com"
    Then the participants of "Dinner" should be "bob@example.com"
    And I should owe $90.00 for "Dinner"

  Scenario: Reject a custom split that does not total 100 percent
    Given I am logged in as "bob@example.com"
    And I am a member of "Apartment 101"
    When I try to create an expense "Utilities" for $100.00 with custom percentages "alice@example.com=60, bob@example.com=20"
    Then the expense creation failed with error "must equal 100%"
    And no expense "Utilities" should exist

  Scenario: Mark payment as complete
    Given I am logged in as "bob@example.com"
    And I am a member of "Apartment 101"
    And I create an expense "Internet" for $60.00
    When I mark my portion as paid for "Internet"
    Then the payment was marked as complete
    And my payment status should be "paid" for "Internet"
    And everyone else should still be pending for "Internet"

  Scenario: Reject negative expense amount
    When I try to create an expense with negative amount
    Then the expense creation failed with error "Amount must be greater than 0"

  Scenario: Require login to create expense
    Given I am not logged in
    When I try to create an expense "Test" for $50.00
    Then I should be redirected to the login page

  Scenario: Calculate precise decimal splits
    Given I am logged in as "bob@example.com"
    And I am a member of "Apartment 101"
    When I create an expense "Pizza" for $33.33
    Then the expense should be split correctly
    And the owed amounts should be $16.67 and $16.66