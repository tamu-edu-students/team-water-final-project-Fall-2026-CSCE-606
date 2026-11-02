# US08 integration: expenses and scheduled chores

Bhaumik Patel owns the dashboard integration. This increment is based on main
at `e4f92e8`, which includes PRs #29, #31, and #32. It incorporates Aditya's
calendar/chore PR #27 at `c3fbaa3`, preserving the original commits, and resolves
its conflicts with the merged expense dashboard. No inventory or voting branch
was available in the repository/forks inspected on November 1, 2026.

## Behavior and user guide

1. Sign in, then select a household you belong to.
2. Read your household's Bills & balances card. Amounts owed and owing remain
   separate from the net amount. A zero net amount with unpaid shares says
   **Payments pending**; it does not settle the shares.
3. Read Chores for scheduled dates from today through seven days ahead, inclusive.
   Dates are expanded by the module's shared `CalendarService`, sorted, and
   previewed five at a time. Each row shows the title, date/time, and current
   household assignees. A longer schedule states the total number of dates.
4. Select the Chores card to create, edit, or delete chores on the module's
   pages. Use Calendar in the header for the current user's household schedule.
5. Use Add expense, All expenses, or Mark as Paid for expense workflows.
   Creating, changing, deleting, or paying through a module is reflected when
   the dashboard is requested again.

The chores card shows all household schedules, not only the current user's
assignments. Calendar's personal view filters to the current user. The existing
application time zone is used and displayed with each chore timestamp. Past,
undated, and day-eight chores do not enter the upcoming preview.

**Scheduled dates are not completion records.** The current Chore model has no
completion status or occurrence-completion records. The UI states that limit;
it does not claim that historic chore dates are unfinished or overdue. The full
US08 story remains open until those semantics and the missing modules exist.

## Completed integration work

- Preserved US01 session/membership checks and both module associations/routes.
- Preserved the expense card and the zero-net-but-unpaid fix from PR #32.
- Added actual chore schedules and retained creator/admin chore permissions.
- Resolved dashboard/controller/model/schema and acceptance/request-test conflicts.
- Fixed duplicate daily, weekly, and monthly chore occurrences when a calendar
  range begins after the occurrence time; three regressions failed before the fix.
- Removed duplicate application authentication declarations and applied safe
  RuboCop formatting corrections to the imported code.
- Fixed the misplaced/copied role-removal migration after it moved into
  `db/migrate`: its class now matches its filename and it removes the legacy
  role only when the newer role constraint has not already been installed.
  Existing admin/member roles are preserved on already-upgraded databases.
- Made the later role-addition migration work with both fresh installs and
  schemas without the role column; regenerated the combined schema.
- Added executable calendar lifecycle, error, authorization, attendee-filter,
  and dashboard navigation scenarios; test actions call real HTTP endpoints.

This branch includes PR #27's module implementation, rather than replacing it
with duplicate dashboard-owned models. Another teammate must review the
combined change before merging it to main. PR #27 need not be merged separately
if this integration is chosen, because its head is included in the history.

## Remaining dependencies

| Requirement | State / next input |
| --- | --- |
| Authorized household selector, members, navigation | Implemented and tested |
| Outstanding shares and due-soon/overdue bills | Implemented and tested through US02 |
| Upcoming chore dates and module navigation | Implemented and tested in this increment |
| Unfinished and overdue chores | US04 must supply completion state, including completion of one recurring occurrence, and confirm whether overdue means per household or per assignee |
| Low-stock inventory alerts | US06 PR/branch, household association, quantity/unit/threshold fields, and inventory/shopping routes needed |
| Open proposals awaiting this user's vote | US09 PR/branch, open/closed/deadline semantics, user-vote association, and proposal routes needed |
| Production | Hosting/URL not finalized in the latest README; no deployment claimed |

Admin/member roles from PR #27 govern chore/event mutations. Expenses remain
creator-only for editing/deletion and users can mark only their own shares
paid. Dashboard read access is membership-based for both roles. Confirm any
team-wide change to expense-admin privileges with the module owner.

## Validation

See [integration verification](us08-integration-verification.md) for exact counts,
coverage, migration checks, and browser limitations. Reproduce using the team's
Ruby 3.4.10 and a dedicated PostgreSQL test database:

```sh
RAILS_ENV=test bin/rails db:prepare
bundle exec rspec
bundle exec cucumber --publish-quiet
bundle exec ruby script/coverage_report.rb
bundle exec rubocop app/models app/controllers app/helpers app/services spec features script/coverage_report.rb config/routes.rb
```

Set `RAILS_ENV` as an environment variable first on PowerShell. Never point the
test database URL at development/production data. The separate historical
foundation and expense verification files are retained as prior-increment evidence.

References: issues #7 and #17. Do not close #17 or mark the full US08 story Done
while completion, inventory, voting, review, or delivery requirements remain.
