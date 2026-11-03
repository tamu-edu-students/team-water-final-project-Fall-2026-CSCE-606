
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
- Expense: a shared cost in a household, with title, description, amount,
  date, optional due date, and the member who paid.
- ExpenseParticipant: one member's share of an expense, with the amount
  owed and a pending/paid status.
- InventoryItem: a supply in one room of a household, with a count and a
  low-stock threshold.
- ShoppingItem: an item on the household's shopping list, with the member
  who added it and, once bought, the member who bought it.

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

### US02 Expense Management Design

**Data model:** A household has many expenses. Each expense belongs to the
household and to the member who paid (`created_by`), and has one
ExpenseParticipant per member who shares the cost. Participants store
`amount_owed`, `payment_status` (`pending` or `paid`), and `paid_at`.

**Splitting:** Expenses can be split equally among all members, equally among
selected members, or by custom percentages. Splits are computed in integer
cents so shares always add up exactly to the expense amount. Custom
percentages must each be between 0 and 100 and total 100%. Only household
members can be participants, so tampered user ids are ignored.

**Consistency:** An expense and its split are saved in one transaction, so an
invalid split leaves no orphaned expense.

**Permissions:** Any household member can add an expense. Only the creator can
edit or delete it, and members can mark only their own share as paid. Once
any share is paid, the amount and split are locked.

**Balances:** `BalanceCalculator` sums pending shares only. For a user it
returns amounts owed to them, amounts they owe, and the net, for one household
or all households. It can also net balances per roommate. Balances are
calculated on request and never stored.

**Routes:** Expense pages are nested under
`/households/:household_id/expenses` (index, new, show, edit, and
`mark_paid`). Access is checked through household membership, and an expense
from another household returns 404.

### US06 Shared Shopping List and Supply Tracking Design

**Owner:** Vasanth. **Story points:** 10 (#14 Inventory Management, 5;
#13 Shared Shopping Lists, 5).

**Data model:** A household has many inventory items and shopping items. An
InventoryItem stores its `room` (living room, kitchen, bedroom, bathroom, or
patio), `name`, `quantity`, and `low_stock_threshold`. A ShoppingItem stores
its `name`, `quantity`, `priority` (low, normal, high), `category`, the member
who added it (`added_by`), and, once bought, `purchased_by` and
`purchased_at`. A shopping item can link to the inventory item it restocks.

**Default items:** The first time a member opens the inventory or the
dashboard, `Household#ensure_default_inventory!` adds starter items for every
room and sets `inventory_seeded_at`, so deleted defaults are not re-created.
A row lock on the household prevents two first visits from seeding twice.

**Low-stock rule:** An item is low on stock when its count is at or below its
threshold. The default threshold of 0 flags items that have run out.

**Shopping list:** The list opens as a pop-up from the inventory page. The
`cart=open` URL parameter opens it, so it works without JavaScript and stays
open after each action. Low-stock supplies are suggested under **Running
low**; adding one links the shopping item to that supply.

**Consistency:** Names are unique within a room for inventory, and among
unbought items for the shopping list, ignoring case. Validations and unique
database indexes enforce both. Counts are kept between 0 and 9,999 by
validations and check constraints, and the +/− buttons update counts inside a
row lock. Marking an item as bought records the buyer and restocks the linked
supply in one transaction.

**Permissions:** Any household member can manage the inventory and the
shopping list, because supplies are shared. Bought items stay as purchase
history and cannot be bought again or removed.

**Routes:** Inventory pagse are nested under
`/households/:household_id/inventory` (index, create, update, destroy, and
`adjust`), and the shopping list under `/households/:household_id/shopping`
(create, destroy, and `purchase`). Both controllers find the household through
`current_user.households` using the shared `InventoryPage` concern, and items
from another household return 404.

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
