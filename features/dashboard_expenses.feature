Feature: Live expense summaries on the household dashboard
  As a household member
  I want to see my actual unpaid shares and upcoming bills
  So I can follow up on payments without confusing net totals with settlement

  Background:
    Given an expense dashboard household with two roommates

  Scenario: An expense created through the app appears on the dashboard
    When my roommate adds an Internet expense for 60 dollars through the app
    And I open the dashboard for "Expense House"
    Then the expense dashboard should show "You owe: $30.00"
    And the expense dashboard should show "Internet"
    And the expense dashboard should offer working expense links

  Scenario: Marking my share paid refreshes the dashboard
    When my roommate adds an Internet expense for 60 dollars through the app
    And I open the dashboard for "Expense House"
    And I submit the dashboard payment form for "Internet"
    Then the expense dashboard status should be "Settled up"
    And only my share of "Internet" should be paid
    And the expense dashboard should have no payment forms

  Scenario: Equal debts still require individual payments
    Given these dashboard expense shares exist:
      | title     | owner | debtor | amount | due_days | status  |
      | Internet  | Alice | Bob    | 30.00  | 1        | pending |
      | Groceries | Bob   | Alice  | 30.00  |          | pending |
    When I open the dashboard for "Expense House"
    Then the expense dashboard status should be "Payments pending"
    And the expense dashboard should show "Net balance: $0.00"
    And the expense dashboard should show "Owed to you: $30.00"
    And the expense dashboard should show "You owe: $30.00"

  Scenario: The due-soon list includes both boundary dates and overdue bills
    Given these dashboard expense shares exist:
      | title       | owner | debtor | amount | due_days | status  |
      | Overdue     | Alice | Bob    | 10.00  | -1       | pending |
      | Today       | Alice | Bob    | 10.00  | 0        | pending |
      | Day five    | Alice | Bob    | 10.00  | 5        | pending |
      | Day six     | Alice | Bob    | 10.00  | 6        | pending |
      | Undated     | Alice | Bob    | 10.00  |          | pending |
      | Paid bill   | Alice | Bob    | 10.00  | 0        | paid    |
      | Others owe  | Bob   | Alice  | 10.00  | 0        | pending |
    When I open the dashboard for "Expense House"
    Then the dashboard due-soon titles should be "Overdue, Today, Day five"

  Scenario: A tampered payment request cannot pay another member's share
    When my roommate adds an Internet expense for 60 dollars through the app
    And I try to pay my roommate's Internet share from the dashboard
    Then the expense dashboard should show "You owe: $30.00"
    And neither share of "Internet" should be paid

  Scenario: Another household's bills do not enter the selected dashboard
    Given I also belong to a household with a private bill
    When I open the dashboard for "Expense House"
    Then the expense dashboard status should be "Settled up"
    And the expense dashboard should not show "Private bill"

  Scenario: Editing an expense refreshes its dashboard share
    When my roommate adds an Internet expense for 60 dollars through the app
    And my roommate changes Internet to 90 dollars through its edit page
    And I open the dashboard for "Expense House"
    Then the expense dashboard should show "You owe: $45.00"

  Scenario: A failed expense edit preserves the dashboard amount
    When my roommate adds an Internet expense for 60 dollars through the app
    And my roommate tries an invalid Internet amount through its edit page
    And I open the dashboard for "Expense House"
    Then the expense dashboard should show "You owe: $30.00"

  Scenario: A paid share locks the expense amount
    When my roommate adds an Internet expense for 60 dollars through the app
    And I open the dashboard for "Expense House"
    And I submit the dashboard payment form for "Internet"
    And my roommate tries to change Internet after my payment
    And I open the dashboard for "Expense House"
    Then the expense dashboard status should be "Settled up"
    And only my share of "Internet" should be paid

  Scenario: Deleting an expense removes it from the dashboard
    When my roommate adds an Internet expense for 60 dollars through the app
    And my roommate deletes Internet through the app
    And I open the dashboard for "Expense House"
    Then the expense dashboard status should be "Settled up"
    And the expense dashboard should not show "Internet"
