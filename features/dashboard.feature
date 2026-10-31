@us08
Feature: Household dashboard foundation
  As a roommate
  I want a dashboard showing chores, bills, inventory alerts, and votes
  So that I can quickly understand what requires my attention

  # Chores are available; the other dashboard summaries are future integrations.

  Scenario: Open my household dashboard
    Given a household named "Water House" exists
    And I am logged in as "bob@example.com"
    And I already belong to "Water House"
    When I open the dashboard for "Water House"
    Then I should see "Household dashboard"
    And I should see "2 members"
    And the dashboard should offer household details for "Water House"

  Scenario: Distinguish available chores from unavailable summaries
    Given a household named "Water House" exists
    And I am logged in as "bob@example.com"
    And I already belong to "Water House"
    When I open the dashboard for "Water House"
    Then chores should be available and other dashboard summaries should be marked unavailable

  Scenario: Require login before opening the dashboard
    Given a household named "Water House" exists
    And I am not logged in
    When I open the dashboard for "Water House"
    Then I should be redirected to the login page

  Scenario: Keep another household private
    Given a household named "Private House" exists
    And I am logged in as "bob@example.com"
    When I open the dashboard for "Private House"
    Then the dashboard request should return not found
    And the dashboard response should not reveal "Private House"

  Scenario: Help a new user get started
    Given I am logged in as "bob@example.com"
    When I open the dashboard home page
    Then I should see "Create or join your first household"
    And I should see "Create a household"
    And I should see "Join a household"

  Scenario: Choose a household from the home page
    Given a household named "Water House" exists
    And I am logged in as "bob@example.com"
    And I already belong to "Water House"
    When I open the dashboard home page
    Then the home page should offer the dashboard for "Water House"

  Scenario: Show only my households on the home page
    Given a household named "Private House" exists
    And I am logged in as "bob@example.com"
    When I open the dashboard home page
    Then the dashboard response should not reveal "Private House"

  Scenario: A former member cannot return to the dashboard
    Given a household named "Water House" exists
    And I am logged in as "bob@example.com"
    And I already belong to "Water House"
    And my membership in "Water House" has ended
    When I open the dashboard for "Water House"
    Then the dashboard request should return not found

  Scenario: Reach the dashboard home page after signing up
    Given I am not logged in
    When I register for a dashboard account with matching passwords
    Then I should see "Welcome to Roommate OS!"
    And I should see "Create or join your first household"

  Scenario: Reject an incomplete signup before granting dashboard access
    Given I am not logged in
    When I register for a dashboard account without a name
    Then I should see "Please correct the following errors:"
    When I open the dashboard home page
    Then I should be redirected to the login page

  Scenario: Reject an incorrect password before granting dashboard access
    Given I am logged in as "bob@example.com"
    And I am not logged in
    When I sign in to the dashboard with an incorrect password
    Then I should see "Invalid email or password"
    When I open the dashboard home page
    Then I should be redirected to the login page

  Scenario: Signing out ends dashboard access
    Given I am logged in as "bob@example.com"
    When I sign out from the dashboard home page
    Then I should be redirected to the login page
    When I open the dashboard home page
    Then I should be redirected to the login page
