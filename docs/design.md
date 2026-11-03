
## Household Management System Design

### Architecture

Roommate OS follows the Model-View-Controller (MVC) architecture
provided by Ruby on Rails.

The application uses PostgreSQL for persistent storage and
Active Record for database interactions.

The current implementation includes:

- User: stores registered user information and authentication data.
- Household: represents a shared household created by a user.
- HouseholdMembership: connects users with households and allows
  multiple users to belong to the same household.

### Model Relationships

- A user can belong to multiple households.
- A household can have multiple users.
- HouseholdMembership represents the many-to-many relationship.
- Each household retains a reference to the user who created it.
- Every household has a unique invitation code.

The creator reference identifies the household creator. The merged
calendar/chore module also uses it in `Household#admin?`; household creators
receive an admin membership when creating a household.

### Authentication

The application uses Rails session-based authentication.

Passwords are securely hashed through `has_secure_password`
and bcrypt rather than stored as plain text.

Users must log in to access household-related functionality.

### Household Authorization

Household information is accessible only to users who belong
to that household.

Controllers use the current user's household associations
when retrieving household information.

Dashboard read access is the same for admin and member roles. Mutation
permissions are module-specific: chore/event creators and household admins
can manage those items; expense edits/deletions remain creator-only and
members can mark only their own expense shares paid.

### Household Creation

When an authenticated user creates a household:

1. The application validates the household name.
2. A new Household record is created.
3. A unique invitation code is generated.
4. A HouseholdMembership record connects the creator with the admin role.
5. The user is redirected to the household details page.

Household creation and membership creation occur within a
database transaction to maintain data consistency.

### Invitation Workflow

Users can join existing households using invitation codes.

1. An existing member shares the household's invitation code.
2. Another registered user logs in.
3. The user enters the invitation code.
4. The application looks up the corresponding household.
5. If the code is valid and the user is not already a member,
   a HouseholdMembership record is created.
6. The user is redirected to the household details page.

Invalid codes are rejected, and duplicate memberships are prevented.

### Important Design Decisions

**Shared dashboard access:** Every household member can view their household's
dashboard. Admin/member roles affect module mutations, not dashboard visibility.

**Separate membership model:** HouseholdMembership supports
many-to-many relationships between users and households.

**Unique invitation codes:** Random invitation codes allow
roommates to join households without requiring public household
directories.

**Server-rendered interface:** Rails views and forms support
essential workflows without requiring JavaScript.

**Membership-based authorization:** Household records are
accessed through the logged-in user's memberships to prevent
unauthorized access to private household information.

### US08 Household Dashboard Design

**Owner:** Bhaumik Patel. **Implementation snapshot:** main `e7d1eb3`,
November 2, 2026, after PRs #33, #34, and #35 merged. This section describes
the dashboard integration and acknowledges the modules supplied by teammates.

#### Request Flow and Access Boundary

1. Successful login resets the session, saves `session[:user_id]`, and redirects
   to `/`. `HomeController#index` lists only the signed-in user's households.
   Users without a household can create or join one.
2. Selecting a household opens `GET /households/:household_id/dashboard`.
   `DashboardsController` requires login and finds the household through
   `current_user.households` before reading members or module data.
3. A missing household or a household belonging only to other users returns
   404. Signed-out users are redirected to login.
4. The controller obtains scoped summaries from shared models/services and
   renders `app/views/dashboards/show.html.erb`. It creates no dashboard table
   and stores no duplicate balances, schedules, or completion records.

#### Data Sources and Display Rules

| Dashboard section | Source and behavior |
| --- | --- |
| Members | `Household#users`, sorted by name/id; highlights the current user and displays admin badges using `Household#admin?`. |
| Bills and balances | US02's `BalanceCalculator` and pending `ExpenseParticipant` records, restricted to this household and user. Shows amounts owed/owing separately from net balances. Equal opposing debts remain **Payments pending** until shares are paid. |
| Due bills | The user's unpaid shares for expenses paid by someone else, with `Expense.due_by(5)` including overdue dates. Undated expenses do not enter the due-date list; pending shares are available as a fallback preview. |
| Scheduled chores | US04's `CalendarService#chores_for`, from today's start through the end of day seven, using the application time zone. Sorts by timestamp, title, and chore id, then displays five dates, current household assignees, and an overflow count. Includes all household assignments, while the personal calendar filters to its user. |
| Inventory | US06 PR #35 calls `ensure_default_inventory!` after membership authorization, then reads household inventory. The module seeds starter items once under a household lock. Alerts show quantity-zero items, ordered by latest update then name, capped at five with an overflow count. |
| Voting | US09 models and routes exist, but the dashboard card remains a placeholder. A future summary must select this household's proposed rules and exclude rules already voted on by the current user. |

#### Navigation and Updates

- Household selection, member display, summary cards, and shared header use
  server-rendered ERB and responsive CSS in `dashboard.css`.
- Expense links target the household's expense pages. Payment forms submit
  `PATCH /households/:household_id/expenses/:id/mark_paid` with the participant
  id; US02 enforces membership and ownership of that share.
- The chore card links to `/households/:household_id/chores`; Calendar in the
  shared header opens `/calendar`. Inventory links to the household's
  `/households/:household_id/inventory` page.
- The next dashboard request reads current records after module changes.
  There is no background polling or cached dashboard snapshot. Core links and
  payment forms work without JavaScript; dynamic enhancements are optional.

#### Integration Decisions and Limits

Bhaumik's PR #29 established the dashboard foundation, PR #32 refined the US02
balance/payment presentation, and PR #33 integrated Aditya's calendar/chore
module with regression coverage. US02's financial implementation, US06's
inventory card, and US09's voting module remain teammate contributions.

The recurrence fix advances both the timestamp and recurrence index before
collecting dates, preventing duplicate daily/weekly/monthly chore occurrences.
Role migration repairs support fresh and previously upgraded schemas without
removing existing roles when the newer constraint is already installed.

Chore schedules do not imply completion status: the model has no completion
records, so the UI explicitly discloses that limitation. Likewise, quantity-zero
inventory alerts do not fulfill the per-item low-stock-threshold criterion.
An implemented empty module is distinguished from an unconnected summary;
the voting card still needs integration despite its module being available.

Dashboard request/service tests and Cucumber workflows cover household
isolation, date boundaries, recurring schedules, payment status, navigation,
and refresh after changes. Historical results are recorded in the
[US08 verification report](us08/us08-integration-verification.md); subsequent
module merges require verification of the final combined revision. Remaining
acceptance and delivery tasks are listed in the [US08 backlog](backlog.md#us08--household-dashboard).
