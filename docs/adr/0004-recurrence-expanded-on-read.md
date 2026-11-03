# 0004: Recurring chores and events expanded on read

**Status:** Accepted

## Context

Chores and calendar events can repeat daily, weekly, or monthly, sometimes with
no end date. Single occurrences of a recurring event can also be moved or
cancelled.

## Decision

In the context of chores and the shared calendar (US-04), facing open-ended
repetition, we decided to store each chore and event once with its recurrence
rule, and to have `CalendarService` expand occurrences for the requested date
range. Moved or cancelled occurrences are stored as `EventException` rows.

## Consequences

- No background job or pre-generated rows are needed, and changing a series
  updates every future occurrence at once.
- The calendar, dashboard, and chore pages all share one expansion logic.
- Per-occurrence state, such as completing one instance of a recurring chore,
  needs extra storage and is not yet implemented.
