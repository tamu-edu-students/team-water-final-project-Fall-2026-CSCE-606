
### US01 — Household Creation & Invitations

**Status:** Implemented and tested

#### Completed Functionality
- User registration, login, and logout
- Household creation with automatic membership
- Equal permissions for all household members
- Unique invitation code generation
- Joining households using invitation codes
- Duplicate membership prevention
- Membership-based household access restrictions
- Validation and error handling

#### Acceptance Testing

Six Cucumber scenarios have been implemented and passed:

1. Create a new household.
2. Join a household using a valid invitation code.
3. Reject an invalid invitation code.
4. Prevent duplicate household memberships.
5. Require authentication before joining a household.
6. Prevent non-members from accessing household details.

RSpec model and request tests also pass.


#### Future Improvements
- Invitation code regeneration
- Rate limiting invitation code submissions
- Invitation expiration, if required
- Further accessibility and security testing

### US08 — Household Dashboard

**Owner:** Bhaumik Patel

**Status (November 2, 2026; main `e7d1eb3`):** Dashboard foundation, expense
follow-up, and scheduled-chore integration are merged. PR #33 received peer
approval and passed CI before merging. The full US08 acceptance criteria are
not yet complete, even though tracker issue #17 is currently closed.

#### Bhaumik's Completed Work

- [PR #29](https://github.com/tamu-edu-students/team-water-final-project-Fall-2026-CSCE-606/pull/29): household selection after login, member-only dashboard, actual member list, responsive layout, shared navigation, and explicit unavailable-module states.
- [PR #32](https://github.com/tamu-edu-students/team-water-final-project-Fall-2026-CSCE-606/pull/32): refined the US02 dashboard integration so a zero net balance with unpaid shares says **Payments pending** instead of **Settled up**; clarified net balances, improved payment-button labels, and added expense workflow coverage.
- [PR #33](https://github.com/tamu-edu-students/team-water-final-project-Fall-2026-CSCE-606/pull/33): added scheduled chores from today through seven days ahead, including recurring dates and current assignees; shows five dates with a total/overflow indication and links to chore management and calendar navigation.
- Resolved conflicts between household, expense, and calendar/chore modules;
  repaired duplicated recurring chore dates and role migration compatibility;
  retained household scoping and module authorization.
- Added request, service, and executable acceptance coverage for dashboard
  navigation, household isolation, calendar workflows, authorization, and refresh
  after changes. Essential dashboard flows use server-rendered links/forms.

#### Current Integration and Ownership

- US01 supplies authentication, households, and memberships. US02's expense
  module and original dashboard balances were supplied through PR #31; the
  dashboard displays pending shares, decimal balances, and bills due within
  five days or already overdue, with actions for the user's own payments.
- Aditya's PR #27 supplies calendar/chore models and management pages; US08
  uses its `CalendarService` instead of creating duplicate scheduling models.
- The teammate-owned US06 PR #35 now supplies inventory and its dashboard
  card: household item counts and up to five items with quantity zero. This
  is an out-of-stock check, not a configurable low-stock threshold.
- The teammate-owned US09 PR #34 supplies rules/voting pages and models.
  The dashboard voting card still displays **Not available yet**; pending-vote
  summaries have not been connected.

#### Verification Evidence

PR #33's resolved revision `a680b37` passed 163 RSpec examples and 59 Cucumber
scenarios / 310 steps locally. Line coverage was 94.47% RSpec, 90.52% Cucumber,
and 95.92% combined; RuboCop inspected 62 files with zero offenses. GitHub CI
also passed. These results describe that integration revision, not a new test
run including the later US09/US06 merges or a production deployment.

See [verification details](us08/us08-integration-verification.md) and the
[US08 design](design.md#us08-household-dashboard-design).

#### Remaining Acceptance and Delivery Work

- Connect proposed household rules that the current user has not voted on to
  the voting card and household-scoped rules pages.
- Add unfinished/overdue chore summaries once US04 supplies completion state,
  including completion of individual recurring occurrences. Scheduled dates
  alone do not establish whether a chore is unfinished.
- Agree and implement the per-item low-stock threshold required by US08;
  current US06 alerts only report quantity zero.
- Verify final combined coverage/lint and mobile/desktop behavior after module
  integration, and retain production deployment and demonstration evidence.
- Reconcile the closed [#17 integration issue](https://github.com/tamu-edu-students/team-water-final-project-Fall-2026-CSCE-606/issues/17) with these remaining criteria by reopening it or creating linked follow-up tasks. [#7](https://github.com/tamu-edu-students/team-water-final-project-Fall-2026-CSCE-606/issues/7) records the completed foundation.

The [integration guide](us08/us08-integration.md) records PR #33's scope; the
dated status above accounts for the subsequent inventory and voting merges.


### US02 — Shared Expense Management

**Status:** Implemented and tested

#### Completed Functionality
- Create expenses with title, description, amount, and date
- Equal split among all household members or a selected subset
- Custom percentage split with a 100% total check
- Exact-cent splitting, with leftover cents distributed so shares always sum to the expense total
- Expense and split saved together in a transaction, so an invalid split leaves no orphaned expense
- Participants limited to household members, so tampered user ids are ignored
- Per-member payment status (pending/paid), with members able to mark only their own portion as paid
- Expense detail page showing the full split, who has paid, and when
- Household balance summary showing amounts owed to you, amounts you owe, and the net balance
- Membership-based access restrictions on all expense actions
- Form that works without JavaScript, with a live percentage total as an enhancement

#### Acceptance Testing

Eight Cucumber scenarios have been implemented:

1. Create an expense with an equal split.
2. Create an expense with a custom split.
3. Split an expense between selected members only.
4. Reject a custom split that does not total 100 percent.
5. Mark a payment as complete.
6. Reject a negative expense amount.
7. Require login to create an expense.
8. Calculate precise decimal splits.

RSpec model, controller, and `BalanceCalculator` service tests cover split rounding, member scoping, validation failures, rollback, authorization, and balance calculations per household and combined.

#### Future Improvements
- Outstanding balances page (route exists, action not yet built)
- Combined balance across all households on the dashboard
- Person-by-person settlement (who owes whom)
- Uniqueness validation and database index for one participant per expense
- Browser-driven test for the login redirect scenario
- Pagination and filtering of the expense list


### US06 — Shared Shopping List and Supply Tracking

**Owner:** Vasanth

**Story Points:** 10 — #14 Inventory Management (5) and #13 Shared Shopping Lists (5)

**Status:** Implemented and tested. Inventory merged in PR #35;
low-stock thresholds and the shopping list follow in the next PR.

#### Completed Functionality — Supply Tracking (#14)
- Inventory organized into five rooms: Living room, Kitchen, Bedroom, Bathroom, and Patio
- Default items for each room, created once per household; deleted defaults are not re-created
- Add, edit, and delete items with a name and count
- Quick +/− buttons that keep counts between 0 and 9,999
- Per-item low-stock threshold; items at or below it are flagged as **Low stock** or **Out of stock**
- Duplicate names rejected within a room (case-insensitive), backed by a unique database index
- Dashboard inventory card links to the inventory and lists up to five low-stock items (US08)

#### Completed Functionality — Shopping List (#13)
- Shopping list button at the top right of the inventory page, showing the number of items to buy
- Pop-up list that works without JavaScript
- Items added with name, quantity, priority (high, normal, low), and category (Groceries, Cleaning, Toiletries, Household, Other)
- Every roommate sees the same list; each item shows who added it, with high-priority items first
- Low-stock supplies are suggested under **Running low** and can be added in one click
- Checking an item off as bought removes it from the active list, records who bought it and when, and restocks the linked supply
- **Recently bought** shows the household's purchase history
- An item can be on the list only once until it is bought
- Household-scoped access; non-members and other households' items return 404

#### Acceptance Testing

Thirteen Cucumber scenarios have been implemented and passed:

1. Choose a room to see its default items.
2. Add an item with a count.
3. Reject a duplicate item in the same room.
4. Edit an item.
5. Delete an item.
6. An item that runs out shows on the dashboard.
7. An item at its low-stock threshold shows on the dashboard.
8. Non-members cannot see the inventory.
9. Open the shopping list from the inventory page.
10. Add an item to the shopping list.
11. Reject an item that is already on the list.
12. A low-stock item is suggested and restocked when bought.
13. Remove an item from the shopping list.

RSpec model and request tests cover validations, thresholds, default items, count limits, priorities and categories, purchases and restocking, authorization, household isolation, and the dashboard card.

#### Verification Evidence

The full suite passed 253 RSpec examples and 80 Cucumber scenarios / 455 steps
locally. Line coverage was 96.06% RSpec, 91.10% Cucumber, and 97.09% combined;
the new inventory and shopping list code has 100% line coverage. RuboCop
inspected 121 files with zero offenses, and Brakeman reported no warnings.

#### Future Improvements
- Editing items already on the shopping list
- Custom rooms and categories
- Shopping list count on the dashboard
