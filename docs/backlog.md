
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

### US09 — Household Rules and Agreements

**Owner:** Dheeraj Sai Madhalam

**Status:** Implemented and tested ([PR #34](https://github.com/tamu-edu-students/team-water-final-project-Fall-2026-CSCE-606/pull/34), Issue [#18](https://github.com/tamu-edu-students/team-water-final-project-Fall-2026-CSCE-606/issues/18))

#### Completed Functionality
- Propose household rules with category tags (`General`, `Noise & Quiet Hours`, `Guests & Visitors`, `Cleanliness & Chores`, `Shared Spaces`, `Food & Kitchen`), title, and description.
- Democratic voting mechanism with dynamically computed majority threshold: $\lfloor \frac{\text{household members}}{2} \rfloor + 1$.
- Automatic casting of the proposer's vote as `approve` on proposal creation.
- Real-time vote tallies and automatic status transitions (`proposed` $\to$ `approved` or `rejected`).
- One-vote-per-member enforcement with unique database index constraint on `[:rule_id, :user_id]`.
- Prominent display of active, approved house rules at the top of the household rules hub.
- Amendment workflow allowing roommates to propose changes to approved rules with explicit rationales.
- Atomic amendment resolution: upon majority approval, the parent rule's active agreement is updated and a new version is recorded in the revision history. If rejected, the active agreement remains unaffected.
- Full chronological revision history (`RuleRevision`) tracking versions, proposers, timestamps, and amendment reasons.
- Dynamic member departure handling: when a roommate leaves the household (`HouseholdMembership` is destroyed), their pending votes on active proposals are discarded, the majority threshold is updated, and open proposals are automatically re-evaluated.
- Strict session authentication (`require_login`) and household membership scoping (`check_membership`), ensuring private and isolated household governance.
- Server-rendered interface styled in full consistency with the Roommate OS Dashboard design system (`.dashboard-shell`, `.dashboard-card`, `.dashboard-overview`, `.dashboard-button`), completely functional without JavaScript.

#### Acceptance Testing

Eight Cucumber scenarios have been implemented and verified in `features/household_rules.feature`:

1. Member proposes a new household rule.
2. Reject proposing a rule with missing details.
3. Voting mechanism approves rule with majority threshold.
4. Voting mechanism rejects rule when majority opposes.
5. Prevent duplicate voting on the same proposal.
6. Propose an amendment to an approved rule.
7. Approve an amendment and track revision history.
8. Prevent non-members from viewing household rules.

Comprehensive RSpec model and request tests (`spec/models/rule_spec.rb`, `spec/models/rule_vote_spec.rb`, `spec/models/rule_revision_spec.rb`, `spec/requests/rules_spec.rb`) cover validations, odd and even household majority math, tie-breaking, departure re-evaluation hooks, amendment validations, cascading deletes, and multi-tenant security isolation.

#### Future Improvements
- Optional voting deadlines/expiration for open proposals (e.g., auto-closing after 7 days).
- Integration into the US08 household dashboard card to highlight proposals requiring the logged-in user's vote.
- Email and in-app notifications when a new proposal or amendment is submitted.
