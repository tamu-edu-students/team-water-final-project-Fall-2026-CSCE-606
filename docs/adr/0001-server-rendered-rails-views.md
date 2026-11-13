# 0001: Server-rendered Rails views that work without JavaScript

**Status:** Accepted

## Context

The Definition of Done requires that core functionality does not depend on
JavaScript, and every feature must be tested with Cucumber and RSpec. The team
works across six independent modules and needs one consistent way to build pages.

## Decision

In the context of all household features, facing the need for accessible,
easily tested pages, we decided to render pages on the server with ERB views
and standard HTML forms, using Turbo only as an enhancement.

## Consequences

- Every workflow works without JavaScript and is testable with Rack::Test in
  Cucumber, without a browser driver.
- Interactions that would usually be client-side, such as the shopping list
  pop-up, need server-side state instead (see ADR 0005).
- Pages reload or morph after each action rather than updating instantly.
