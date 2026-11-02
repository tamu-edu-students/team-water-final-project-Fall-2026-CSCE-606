@us09
Feature: Household Rules and Agreements
  As a roommate
  I want to propose and vote on household rules
  So that expectations are clear and agreed upon

  Background:
    Given a household named "Pine Villa" exists
    And I am logged in as "alice@example.com"
    And I am a member of "Pine Villa"

  Scenario: Member proposes a new household rule
    When I propose a rule "Quiet Hours" with category "Noise & Quiet Hours" and description "No loud noise after 10 PM"
    Then the rule "Quiet Hours" was proposed successfully
    And "Quiet Hours" should be listed under active proposals

  Scenario: Reject proposing a rule with missing details
    When I try to propose a rule with empty title
    Then rule creation should fail with an error
    And no rule should exist

  Scenario: Voting mechanism approves rule with majority threshold
    Given another roommate "bob@example.com" belongs to "Pine Villa"
    And I propose a rule "Dishwasher Duty" with category "Cleanliness & Chores" and description "Empty dishwasher every morning"
    When "bob@example.com" votes "approve" on "Dishwasher Duty"
    Then the rule "Dishwasher Duty" should be approved
    And "Dishwasher Duty" should be displayed under approved house rules

  Scenario: Voting mechanism rejects rule when majority opposes
    Given another roommate "bob@example.com" belongs to "Pine Villa"
    And I propose a rule "Early Bedtime" with category "General" and description "Lights off at 8 PM"
    When "bob@example.com" votes "reject" on "Early Bedtime"
    Then the rule "Early Bedtime" should be rejected

  Scenario: Prevent duplicate voting on the same proposal
    Given another roommate "bob@example.com" belongs to "Pine Villa"
    And I propose a rule "Guest Limit" with category "Guests & Visitors" and description "Max 2 overnight guests"
    When I try to vote "approve" on "Guest Limit" again
    Then I should see "You have already voted on this proposal."

  Scenario: Propose an amendment to an approved rule
    Given another roommate "bob@example.com" belongs to "Pine Villa"
    And an approved rule "Weekend Guests" exists in "Pine Villa" with description "Guests allowed on weekends"
    When I propose an amendment to "Weekend Guests" with description "Guests allowed on weekends with 24h notice" and reason "Need advance notice"
    Then the amendment for "Weekend Guests" was proposed successfully
    And the amendment should be listed under active proposals

  Scenario: Approve an amendment and track revision history
    Given another roommate "bob@example.com" belongs to "Pine Villa"
    And an approved rule "Weekend Guests" exists in "Pine Villa" with description "Guests allowed on weekends"
    And I propose an amendment to "Weekend Guests" with description "Guests allowed on weekends with 24h notice" and reason "Need advance notice"
    When "bob@example.com" votes "approve" on the amendment for "Weekend Guests"
    Then the rule "Weekend Guests" should have updated description "Guests allowed on weekends with 24h notice"
    And the revision history for "Weekend Guests" should show 2 versions

  Scenario: Prevent non-members from viewing household rules
    Given I am logged in as "outsider@example.com"
    When I try to view rules for "Pine Villa"
    Then I should be redirected to the home page with an alert
