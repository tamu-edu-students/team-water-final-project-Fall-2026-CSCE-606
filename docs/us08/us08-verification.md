# US08 Foundation Verification

Verification performed locally on October 30, 2026, against the US01-based
dashboard branch. These results do not verify the pending live summaries or a
production deployment.

| Check | Result |
| --- | --- |
| RSpec, full existing suite plus 12 new dashboard request examples | 52 examples, 0 failures |
| Cucumber, full suite including 12 new dashboard/access scenarios | 18 scenarios, 88 steps, all passed |
| RSpec line coverage | 113/120 lines, 94.16% |
| Cucumber line coverage | 110/120 lines, 91.66% |
| Combined line coverage | 113/120 lines, 94.16% |
| RSpec / Cucumber / combined branch coverage | 87.50% / 81.25% / 87.50% |
| Dashboard controller coverage | All executable lines covered by each suite |
| RuboCop | 34 files inspected, zero offenses in models, controllers, helpers, specs, features, coverage script, and routes |
| Browser journey | Signup, empty household selector, household creation, dashboard navigation |
| Responsive check | Desktop and 390 x 844 viewport; single-column cards on mobile, no horizontal overflow |
| JavaScript requirement | Cucumber uses Rack requests; access, forms, and dashboard content are server rendered |

The test-first run of the 12 new RSpec examples initially failed because the
dashboard route and view did not exist. The completed implementation passes.
Privacy checks cover signed-out users, non-members, former members, unknown
households, multiple households, and escaped user-provided names.

Local environment: Windows, Ruby 4.0.6, Rails 8.1.4, PostgreSQL 18.1, Bundler
4.0.16. The project specifies Ruby 3.4.10 / Bundler 4.0.19, so the existing Linux
CI run remains required before merge. Local Windows dependency resolution is
kept in ignored `.bundle/Gemfile.windows` and its lockfile; the team's tracked
Gemfile and Gemfile.lock are unchanged. No credentials or local database files
are included in the change.

An isolated PostgreSQL instance on loopback port 55438 was used, with separate
`roommate_us08_test` and `roommate_us08_preview` databases. The preview runs on
loopback port 3108 with synthetic demonstration data. Optional Windows image
codec warnings did not prevent Rails, tests, or the browser preview from running.

Generated coverage reports and local logs are ignored by Git. To reproduce,
follow the commands in [the US08 guide](us08-dashboard.md). Coverage measures
Ruby code, not CSS or ERB accessibility. A complete accessibility audit, real
module integration tests, peer review, and production validation remain open.
