# Add the household dashboard foundation

After login, members currently have no dashboard entry point. This change adds
a household selector and a member-only dashboard showing the selected
household's members, navigation to invitations, and responsive sections for
chores, bills/balances, inventory alerts, and voting.

The four summaries explicitly remain unavailable until their module data and
routes are integrated. No module-owned schemas or role permissions are added.
References #7 and #17; the full US08 integration story remains open.

Validation: 52 passing RSpec examples, 18 passing Cucumber scenarios (88 steps),
and zero RuboCop offenses across 34 files. Line coverage is 94.16% RSpec, 91.66%
Cucumber, and 94.16% combined. Desktop and 390 x 844 browser layouts were checked.

Local checks used Windows/Ruby 4.0.6 with an ignored local lockfile. The tracked
Gemfile.lock is unchanged; the team's Ruby 3.4.10 Linux CI must pass before merge.
See `docs/us08-verification.md` for branch coverage and test scope, and
`docs/us08-dashboard.md` for module contracts, role-policy questions, and the
remaining review/deployment requirements.
