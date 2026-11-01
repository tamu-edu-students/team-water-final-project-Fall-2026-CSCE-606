# US08 expense integration follow-up verification

Checked locally on October 31, 2026. Base: PR #31 at
`562a5f06aa0529442f9ddc122988b7941a779d3e`. This verifies the expense/dashboard
branch, not a combined merge with calendar/chores PR #27 or production.

The follow-up fixes the misleading "All settled up" message when equal incoming
and outgoing shares remain unpaid. Net amounts are explicitly labelled, and
payment buttons identify their expense and use the dashboard button style.

| Check | Result |
| --- | --- |
| RSpec | 116 examples, 0 failures (5 new dashboard regression examples) |
| Cucumber | 36 scenarios, 207 steps, all passed (10 new dashboard expense scenarios) |
| RSpec line coverage | 310/321, 96.57% |
| Cucumber line coverage | 296/321, 92.21% |
| Combined line coverage | 314/321, 97.81% |
| RSpec / Cucumber / combined branch coverage | 90.00% / 70.00% / 90.00% |
| RuboCop, new Ruby files | 2 files, zero offenses |
| RuboCop, full scope | 45 files, zero offenses |

The two inherited spacing offenses in the existing dashboard step definition
were corrected. The full RuboCop scope covers models, controllers, helpers,
services, specs, features, the coverage script, and routes.

The settlement regression failed against the unchanged PR #31 view before the
fix. Additional tests verify exact decimal totals, overdue/today/day-five
boundaries, later/undated/paid exclusions, other households, real expense-page
links, payment form submission, authorization, edits, failed edits, paid-amount
locking, deletion, and subsequent dashboard refresh. Given steps may create
fixtures; When steps exercise application HTTP requests instead of setting
success flags or calling model mutations directly.

Environment: Windows, Ruby 4.0.6, Rails 8.1.4, Bundler 4.0.16, PostgreSQL 18.1.
An ignored local Gemfile/lockfile uses the installed Windows dependencies;
tracked dependencies and schemas are unchanged by this follow-up. The test DB
is the isolated `roommate_pr31_review_test` on loopback port 55438. Linux CI with
the team's Ruby 3.4.10 remains required. Run commands in the
[US08 guide](us08-dashboard.md) to reproduce the tests and coverage reports.

The browser automation runtime failed to start, including after a session reset,
so this follow-up has no new desktop/mobile screenshot verification. The request
and acceptance tests render the actual ERB and exercise forms without JavaScript.
The foundation's prior responsive check remains historical evidence only.

The original [foundation verification](us08-verification.md) remains historical
evidence. The full US08 story still depends on chore completion semantics,
inventory and voting modules, peer review, and deployment validation.
