# Historical planning example. This file is not loaded by Cucumber.
# Executable foundation scenarios: features/dashboard.feature.
# Live-summary requirements and missing integrations: docs/us08-dashboard.md.
Feature: Household Dashboard
  As a roommate
  I want a centralized dashboard
  So that I know what needs attention

  Background:
    Given I am logged in to my household

  Scenario: Viewing complete dashboard
    Given I have 2 upcoming chores
    And I owe "75.00" in expenses
    And 1 bill is due this week
    When I view the dashboard
    Then I see "2 chores due"
    And I see "Balance: -$75.00"
    And I see "1 upcoming bill"

  Scenario: Empty household dashboard
    Given no activities exist
    When I view the dashboard
    Then I see "No upcoming tasks"
    And I see welcome message

  Scenario: Mobile responsive dashboard
    When I access dashboard on mobile
    Then layout adjusts to single column
    And all information remains accessible
