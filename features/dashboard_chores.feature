Feature: Household chores and expenses on one dashboard
  As a household member
  I want to see upcoming chore dates alongside my bills
  So I can plan household responsibilities

  Background:
    Given an expense dashboard household with two roommates

  Scenario: Chores and bills appear together with working navigation
    When my roommate adds an Internet expense for 60 dollars through the app
    And I add "Clean kitchen" due in 1 days through the chores page
    And I open the dashboard for "Expense House"
    Then the chore dashboard should list "Clean kitchen"
    And the expense dashboard should show "You owe: $30.00"
    And I can open chores and the calendar from the dashboard

  Scenario: Both date boundaries are included in the upcoming schedule
    Given these chore dates exist:
      | title      | due_days |
      | Yesterday  | -1       |
      | Today      | 0        |
      | Day seven  | 7        |
      | Day eight  | 8        |
      | Undated    |          |
    When I open the dashboard for "Expense House"
    Then the chore schedule titles should be "Today, Day seven"

  Scenario: A recurring chore is expanded with a bounded dashboard preview
    Given a daily chore called "Dishes" began 10 days ago
    When I open the dashboard for "Expense House"
    Then the chore dashboard should show 5 scheduled dates out of 8

  Scenario: Editing and deleting a chore refreshes the dashboard
    When I add "Clean kitchen" due in 1 days through the chores page
    And I move "Clean kitchen" outside the dashboard date range
    And I open the dashboard for "Expense House"
    Then the chore dashboard should have no scheduled dates
    When I delete "Clean kitchen" through the chores page
    And I open the dashboard for "Expense House"
    Then the chore dashboard should show "0 chores for this household"

  Scenario: Other households cannot leak chore details into the dashboard
    Given I also belong to a household with a private bill
    And that other household has a private chore
    When I open the dashboard for "Expense House"
    Then the chore dashboard should have no scheduled dates
    And I should not see the private chore

  Scenario: A non-creator member cannot change someone else's chore
    Given my roommate created a chore called "Roommate task"
    When I try to change my roommate's chore from its edit route
    Then the chore should remain unchanged
    When I open the dashboard for "Expense House"
    Then the chore dashboard should list "Roommate task"

  Scenario: Invalid assignment does not create a dashboard responsibility
    When I try to add a chore with an outsider assignment
    And I open the dashboard for "Expense House"
    Then the chore dashboard should have no scheduled dates
    And the chore dashboard should show "0 chores for this household"
