
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


### US02 — Household Creation & Invitations

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
- Edit and delete expenses
- Outstanding balances page (route exists, action not yet built)
- Combined balance across all households on the dashboard
- Person-by-person settlement (who owes whom)
- Uniqueness validation and database index for one participant per expense
- Browser-driven test for the login redirect scenario
- Pagination and filtering of the expense list