# 0003: Invitation codes for joining a household

**Status:** Accepted

## Context

Roommates need a simple way to join an existing household. Emailed invitation
links would require outgoing email in every environment, plus expiry and
single-use tracking.

## Decision

In the context of household invitations (US-01), facing the cost of email
delivery, we decided that each household has a unique random invitation code
(`has_secure_token :invite_code`) that members share and others enter to join.

## Consequences

- Joining works without any email service.
- A unique index prevents duplicate codes, and a unique membership index
  prevents joining the same household twice.
- Anyone who has the code can join, so members should share it only with people
  they trust. Code regeneration and expiry remain future improvements.
