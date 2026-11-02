# US08 integration verification — November 1, 2026

## November 2 conflict-resolution verification

Merged main `92d8494` into PR #33 after PR #27 landed. Resolved conflicts in
README, dashboard controller/view, schema, and dashboard acceptance steps.
Preserved the team's README cleanup/project links and current Scrum records.
The application, migrations, and executable tests match the previously tested
integration; the complete suites were rerun after resolving the conflicts:
163 RSpec examples, 59 Cucumber scenarios / 310 steps, all passing; line coverage
94.47% / 90.52% / 95.92%; RuboCop 62 files, zero offenses. Fresh migration
results below are from the earlier run, not a new migration run today.
No new browser visual verification was performed during conflict resolution.

## Original integration verification

Verified the integration of main `e4f92e8` and calendar/chore PR #27 `c3fbaa3`,
including the new dashboard schedule, migration fixes, and recurrence fix.

| Check | Result |
| --- | --- |
| RSpec | 163 examples, 0 failures |
| Cucumber | 59 scenarios, 310 steps, all passed |
| RSpec line coverage | 718/760, 94.47% |
| Cucumber line coverage | 688/760, 90.52% |
| Combined line coverage | 729/760, 95.92% |
| RSpec / Cucumber / combined branch coverage | 81.73% / 72.60% / 85.84% |
| Dashboard controller | 22/22 executable lines in each suite |
| RuboCop | 62 files, zero offenses across models/controllers/helpers/services/specs/features, routes, and coverage script |
| Fresh database migration | All 11 migrations passed on an empty PostgreSQL database created from template0 |
| Existing role schema | Legacy role-removal migration skipped removal when the newer role constraint existed |

The three new daily/weekly/monthly recurrence regressions failed before the
index-alignment fix and pass afterward. Dashboard tests cover today/day-seven
boundaries, historical recurrence, five-row preview limits, current assignees,
HTML escaping, multiple household memberships, and refresh after edits/deletion.
Calendar scenarios cover create/read/update/delete, moved/cancelled occurrences,
whole-series changes, invalid inputs, creator/admin/member permissions,
non-members, signed-out users, missing resources, and attendee filtering.

Local environment: Windows, Ruby 4.0.6, Rails 8.1.4, Bundler 4.0.16, PostgreSQL
18.1. The ignored local Gemfile/lockfile uses installed Windows gems; no local
database files, credentials, logs, or preview data are committed. Linux CI with
Ruby 3.4.10 remains required for the published revision.

Test databases are isolated on loopback port 55438. The migration test database
`roommate_integration_final_migrations` began with no application tables and
completed all 11 migrations. The generated combined schema retains expenses,
events, chores, memberships, role constraints, and their relationships.

No new desktop/mobile visual verification is claimed. Native Computer Use was
stopped; the user then requested Chrome-extension-only checks. The extension
reported "browser access host is unavailable". Actual server-rendered HTML,
navigation, and HTTP form/API workflows are verified by the automated suites.

These results validate the available integration increment, not the missing
inventory/voting/completion features or a production deployment. The current
dependency checklist is in [the integration guide](us08-integration.md).
