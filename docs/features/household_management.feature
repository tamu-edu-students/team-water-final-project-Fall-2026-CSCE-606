Feature: Household management
  As a registered Roommate OS user
  I want to create and join households
  So that I can manage shared household responsibilities with my roommates

  Scenario: Create a new household
    Given I am logged in as "alice@example.com"
    When I create a household named "Apartment 101"
    Then I should see the household "Apartment 101"
    And I should be a member of "Apartment 101"

  Scenario: Join a household using a valid invitation code
    Given a household named "Apartment 101" exists
    And I am logged in as "bob@example.com"
    When I join "Apartment 101" using its invitation code
    Then I should see the household "Apartment 101"
    And I should be a member of "Apartment 101"

  Scenario: Reject an invalid invitation code
    Given I am logged in as "bob@example.com"
    When I try to join a household with the code "INVALID123"
    Then I should see "Invalid invitation code."

  
  Scenario: Prevent duplicate household memberships
    Given a household named "Apartment 101" exists
    And I am logged in as "bob@example.com"
    And I already belong to "Apartment 101"
    When I join "Apartment 101" using its invitation code
    Then I should see "You are already a member of this household."
    And I should have exactly one membership in "Apartment 101"

  Scenario: Require login before joining a household
    Given a household named "Apartment 101" exists
    And I am not logged in
    When I try to join "Apartment 101" using its invitation code
    Then I should be redirected to the login page
    And I should not have joined "Apartment 101"

  Scenario: Prevent non-members from viewing household details
    Given a household named "Apartment 101" exists
    And I am logged in as "bob@example.com"
    When I try to view the household "Apartment 101"
    Then I should receive a not found response
