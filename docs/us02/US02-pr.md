## Expense tracking, balances, and dashboard integration

Adds shared-expense tracking to households: creating, splitting, editing, and paying expenses, plus balance summaries on the household page and dashboard.

### What's included

**Expenses**
- Create expenses with title, description, amount, date, and optional due date
- Split equally, equally among selected members, or by custom percentages (must total 100%)
- Splits work in integer cents, so shares always sum exactly to the expense total
- Expense and split save in one transaction, so an invalid split leaves no orphaned expense
- Participants are limited to household members, so tampered user ids are ignored
- Expense detail page showing the full split, who has paid, and when
- Expense index page listing all household expenses with the user's share and status
- Creator-only edit and delete
- Editing can change the amount, split type, and members. "Keep current split" is the default and rescales shares proportionally when only the amount changes
- Amount and split are locked once any share is marked paid
- The new/edit form works without JavaScript. JS only adds a live percentage total

**Payments and balances**
- Members can mark only their own share as paid
- `BalanceCalculator` returns owed-to-me, I-owe, and net, for one household, all households combined, and per household
- `BalanceCalculator#by_person` nets balances per roommate ("Bob owes you $15")
- Household page shows owed, owes, and net balance

**Dashboard (`Bills & balances` card)**
- Live status (Owed to you / You owe / Settled up), net balance, and totals
- Who owes you and who you owe
- Bills due in the next 5 days, including overdue ones, otherwise what you still owe
- "Mark as Paid" button on each pending share
- Links to the expense pages, the add-expense form, and the expense index

### Database
- New migration adds `expenses.due_date` (date, nullable, indexed). Existing expenses get `NULL` and are unaffected
- Run `bin/rails db:migrate`

### Routes
- Merged `resource :dashboard` and `resources :expenses` under `resources :households`
- New helpers in use: `household_dashboard_path`, `household_expenses_path`, `household_expense_path`, `edit_household_expense_path`, `new_household_expense_path`, `mark_paid_household_expense_path`
- `balances_household_expenses_path` still exists but has no controller action, so nothing links to it

### Testing
- Model specs: `Expense` (validations, equal and custom splits, rounding, member scoping, `rescale_shares`, `replace_split`, due dates) and `ExpenseParticipant`
- Controller specs: create, show, index, update, destroy, `mark_paid`, membership and creator authorization, rollback on bad splits
- Service spec: `BalanceCalculator` per household, combined, by household, and by person
- Request specs: dashboard expense integration (balances, per-person lists, due-soon bills, Mark as Paid, household scoping, HTML escaping)
- Cucumber: expense scenarios for equal, selected-member, and custom splits, invalid percentages, negative amounts, and payments
- The old dashboard test that expected all four cards to say "Not available yet" was updated, since the Bills card is now live

### Notes for reviewers
- Net balances are aggregate and per-person. Payments are still marked per expense share, so a netted figure on the dashboard isn't a single payment
- The combined balance includes expenses from households the user has since left
- `expenses.total_amount` is unused and left in place
- The login-redirect Cucumber scenario only sets a flag and does not exercise the app's login check

### Known limitations and follow-ups
- Uniqueness validation and a unique index for one participant per expense
- Pagination and filtering on the expense index
- Reminders for upcoming or overdue bills
- Partial re-split after a payment (currently locked)
- Browser-driven test for the login redirect