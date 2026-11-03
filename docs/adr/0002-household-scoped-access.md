# 0002: Household-scoped access to every module

**Status:** Accepted

## Context

A user can belong to several households, and each household's expenses, chores,
rules, and inventory are private to its members. Without a shared rule, one
module could leak another household's data.

## Decision

In the context of every household module, facing the risk of cross-household
data leaks, we decided that every request must confirm the user's membership
before reading household data, and that records are looked up through their
household (for example `@household.inventory_items.find(id)`) rather than by id
alone.

## Consequences

- The dashboard, chores, inventory, and shopping list load the household through
  `current_user.households`, so a non-member receives 404 and cannot tell whether
  the household exists.
- Expenses and rules check membership after loading the household and redirect
  non-members with an alert; the JSON events API returns 403.
- A record from another household is never found through the current household,
  even for a user who belongs to both.
- The response for non-members differs between modules; aligning them on 404 is
  a possible future cleanup.
