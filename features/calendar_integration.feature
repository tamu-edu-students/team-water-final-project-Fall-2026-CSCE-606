Feature: Shared calendar integration
  As a household member
  I want calendar changes and permissions to work with the household dashboard
  So that the schedule is accurate and private

  Background:
    Given an expense dashboard household with two roommates

  Scenario: A single event can be created, listed, edited and deleted
    When I create a "NONE" calendar event through the API
    Then the event appears in my calendar and household feed
    When I update the single event and its attendees
    Then the updated event appears once in the calendar
    When I delete the whole event
    Then the calendar event is removed

  Scenario: A moved recurring event appears at its destination date
    When I create a "DAILY" calendar event through the API
    And I move one occurrence beyond the series end
    Then the moved event appears on its destination date
    When I cancel that occurrence
    Then the destination date has no event
    When I update the entire event series
    And I delete the whole event
    Then the calendar event is removed

  Scenario: Event permissions distinguish creators, admins and other members
    When I create a "NONE" calendar event through the API
    Then another household member cannot edit or delete my event
    And a household admin can edit my event
    And an outsider cannot read or change the household calendar
    And a signed-out user cannot read the calendar API

  Scenario Outline: Invalid event data is rejected without saving
    Given I create a "NONE" calendar event through the API
    When I submit an event with invalid "<field>" set to '<value>'
    Then the event API should reject the request without saving
    And the event appears in my calendar and household feed

    Examples:
      | field            | value                 |
      | name             | ""                    |
      | start_timestamp  | "bad-time"            |
      | start_timestamp  | ""                    |
      | end_timestamp    | "2026-11-03T08:00:00Z"|
      | all_day          | "yes"                 |
      | recurrence_until | "bad-date"            |
      | recurring        | "YEARLY"              |
      | attendee_ids     | "invalid"             |
      | attendee_ids     | ["bad-id"]            |
      | attendee_ids     | [-1]                  |

  Scenario: Calendar range and member filters reject invalid requests
    When I create a "DAILY" calendar event through the API
    Then invalid calendar ranges and member filters are rejected
    And the event list respects its attendee filter

  Scenario: Invalid mutations preserve the stored event
    When I create a "DAILY" calendar event through the API
    Then invalid event updates and occurrence requests are rejected
    And the original recurring event is unchanged

  Scenario: Invalid single-event changes preserve the stored event
    When I create a "NONE" calendar event through the API
    Then invalid single-event updates are rejected
    And the event appears in my calendar and household feed
