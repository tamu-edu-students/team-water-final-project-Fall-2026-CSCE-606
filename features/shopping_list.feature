@inventory
Feature: Household shopping list
  As a roommate
  I want a shared shopping list for household supplies
  So that we can coordinate purchases and avoid running out

  Background:
    Given a household named "Pine Villa" exists
    And I am logged in as "alice@example.com"
    And I am a member of "Pine Villa"

  Scenario: Open the shopping list from the inventory page
    When I open the shopping list for "Pine Villa"
    Then the shopping list should show "To buy (0)"
    And I should see "Nothing to buy right now."

  Scenario: Add an item to the shopping list
    When I add "Milk" with quantity 2 and "high" priority to the shopping list
    Then the shopping list should show "Milk"
    And the shopping list should show "Added by Alice"
    And the shopping list should show "High priority"

  Scenario: Reject an item that is already on the list
    Given "Milk" is on the shopping list
    When I add "milk" with quantity 1 and "normal" priority to the shopping list
    Then I should see "Name is already on the shopping list"

  Scenario: A low-stock item is suggested and restocked when bought
    When I lower the count of "Dish soap" by one
    And I open the shopping list for "Pine Villa"
    Then the shopping list should suggest "Dish soap"
    When I add the suggested "Dish soap" to the shopping list
    And I mark "Dish soap" as bought
    Then "Dish soap" should have a count of 1
    And the shopping list should show "Bought by Alice"

  Scenario: Remove an item from the shopping list
    Given "Milk" is on the shopping list
    When I remove "Milk" from the shopping list
    Then I should see "Nothing to buy right now."
