# Expenses Integration Guide

What the dashboard needs to show expense and balance data. No migrations are required; the existing schema already has everything.

## Models

```ruby
class Household < ApplicationRecord
  has_many :expenses
end

class Expense < ApplicationRecord
  belongs_to :household
  belongs_to :created_by, class_name: "User", foreign_key: "created_by_id"
  has_many :expense_participants, dependent: :destroy
  has_many :participants, through: :expense_participants, source: :user
end

class ExpenseParticipant < ApplicationRecord
  belongs_to :expense
  belongs_to :user   # the person who owes this share
end
```

`ExpenseParticipant`'s associations are inferred from how the specs and queries use it. Confirm with `grep -n belongs_to app/models/expense_participant.rb`.

## Fields

**`expenses`**

| Column | Type | Notes |
|---|---|---|
| `household_id` | bigint | scope all queries by this |
| `created_by_id` | bigint | the person who paid |
| `title` | string | |
| `description` | text | optional |
| `amount` | decimal | the real total, validated > 0 |
| `expense_date` | date | |
| `created_at`, `updated_at` | datetime | |

`expenses.total_amount` exists but is never written. Ignore it and use `amount`. There is no due-date column, so "bills due soon" can't be driven by this data.

**`expense_participants`** (one row per member's share)

| Column | Type | Notes |
|---|---|---|
| `expense_id` | bigint | |
| `user_id` | bigint | who owes this share |
| `amount_owed` | decimal | |
| `payment_status` | string | `"pending"` or `"paid"` |
| `paid_at` | datetime | set when marked paid |

## Routes

All are nested under `/households/:household_id/expenses`.

| Purpose | Helper | Notes |
|---|---|---|
| Add expense | `new_household_expense_path(household)` | |
| View expense | `household_expense_path(household, expense)` | |
| Edit expense | `edit_household_expense_path(household, expense)` | creator only |
| Mark share paid | `mark_paid_household_expense_path(household, expense)` | PATCH, needs `participant_id`; only that share's own user can do it |
| All expenses list | `household_path(household)` | the household page lists them |

Do not link to `household_expenses_path` (index) or `balances_household_expenses_path`. The routes exist, but the controller has no actions for them.

## Balance service

```ruby
BalanceCalculator.new(@household, current_user).calculate
# => { total_owed_to_me:, total_i_owe:, net_balance: }   (BigDecimals, zeros if no expenses)

BalanceCalculator.for_all_households(current_user)   # combined across households
BalanceCalculator.by_household(current_user)         # { household_id => {...} }
```

The file is `app/services/balance_calculator.rb` and must be shared along with the models.

## Dashboard controller additions

`DashboardsController#show` already scopes `@household` through `current_user.households`, so access control is covered. Add:

```ruby
@balance = BalanceCalculator.new(@household, current_user).calculate

# Optional: shares the current user still owes
@pending_shares = ExpenseParticipant
  .includes(expense: :created_by)
  .joins(:expense)
  .where(user: current_user, payment_status: "pending")
  .where(expenses: { household_id: @household.id })
  .where.not(expenses: { created_by_id: current_user.id })
  .order("expenses.expense_date DESC")
  .limit(5)

# Optional: recent activity
@recent_expenses = @household.expenses
                             .includes(:created_by)
                             .order(expense_date: :desc, created_at: :desc)
                             .limit(5)
```

## Rules to respect

- **Pending only:** balances count only `payment_status = "pending"`. Paid shares drop out.
- **Net balance:** it's an aggregate, not person-by-person.
- **Creator's own share:** it is a normal row, but the balance math ignores it.
- **Permissions:** only the creator can edit or delete an expense. Show the edit link only when `expense.created_by == current_user`.
- **Locks:** once any share is paid, the amount and split can't be changed.
- **Shares add up:** a split's shares always sum exactly to `expense.amount`.
- **Dependency:** the dashboard controller uses `current_user.households`, so `User` needs `has_many :households, through: :household_memberships`. The expenses feature itself doesn't depend on it.