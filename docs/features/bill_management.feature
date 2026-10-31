Feature: Bill Management
  As a roommate
  I want to track bills and payments
  So that all bills are paid on time

  Background:
    Given I am a member of "Apartment 101"
    And there are 3 roommates

  Scenario: Adding recurring bill
    When I add bill "Electricity"
    And I set amount to "120.00"
    And I set due date to "15th monthly"
    And I click "Save Bill"
    Then bill appears with "40.00" per person
    And reminder is scheduled for 3 days before

  Scenario: Bill payment tracking
    Given I owe "40.00" for electricity
    When I mark my portion as paid
    Then my status shows "Paid"
    And household sees "1 of 3 paid"

  Scenario: Overdue bill warning
    Given electricity bill is past due
    When I view the dashboard
    Then I see "OVERDUE: Electricity"
    And unpaid members are highlighted

  Scenario: Custom bill splitting
    When I add bill with custom split
    And I set percentages "50%, 30%, 20%"
    Then amounts show correctly calculated
