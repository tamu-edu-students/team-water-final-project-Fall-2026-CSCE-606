@inventory
Feature: Household inventory
  As a roommate
  I want to track the items in each room of our home
  So that we know what we have and what has run out

  Background:
    Given a household named "Pine Villa" exists
    And I am logged in as "alice@example.com"
    And I am a member of "Pine Villa"

  Scenario: Choose a room to see its default items
    When I open the inventory for "Pine Villa"
    Then I should see "Choose a room to get started"
    When I choose the "kitchen" room
    Then the room should list "Cooking pots, Cups, Dish soap, Plates, Trash bags"

  Scenario: Add an item with a count
    When I add "Paper towels" with a count of 3 to the "kitchen" room
    Then I should see "Paper towels added to Kitchen."
    And "Paper towels" should have a count of 3

  Scenario: Reject a duplicate item in the same room
    When I add "dish SOAP" with a count of 1 to the "kitchen" room
    Then I should see "Name already exists in this room"

  Scenario: Edit an item
    When I edit "Plates" to be named "Dinner plates" with a count of 8
    Then I should see "Dinner plates updated."
    And "Dinner plates" should have a count of 8

  Scenario: Delete an item
    When I delete "Plates"
    Then I should see "Plates removed from Kitchen."
    And the room should not list "Plates"

  Scenario: An item that runs out shows on the dashboard
    When I lower the count of "Dish soap" by one
    Then "Dish soap" should have a count of 0
    When I open the dashboard for "Pine Villa"
    Then the inventory card should show "1 out of stock"
    And the inventory card should show "Dish soap"

  Scenario: Non-members cannot see the inventory
    Given I am logged in as "outsider@example.com"
    When I open the inventory for "Pine Villa"
    Then I should receive a not found response
