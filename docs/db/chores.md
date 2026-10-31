# Chore Management Database Schema

Chores are stored independently from events. The combined calendar reads chores
with due dates and expands recurring dates at read time; it does not create
event records for chores.

## Tables

### `chores`

| Column | Type | Constraints and meaning |
|---|---|---|
| `id` | BIGINT | Primary key |
| `household_id` | BIGINT | Required foreign key to `households`; deleting the household cascades to its chores |
| `created_by_id` | BIGINT | Required foreign key to `users`; chore creator |
| `title` | VARCHAR(200) | Required |
| `description` | TEXT | Optional |
| `due_at` | TIMESTAMPTZ | Optional initial due date and time |
| `frequency` | VARCHAR | Required; `NONE`, `DAILY`, `WEEKLY`, or `MONTHLY`; defaults to `NONE` |
| `created_at` | TIMESTAMP | Rails creation timestamp |
| `updated_at` | TIMESTAMP | Rails update timestamp |

The database enforces the frequency values with the `chores_valid_frequency`
check constraint. An index on `(household_id, due_at)` supports household date
range lookups.

### `chore_assignments`

This join table assigns chores to household members.

| Column | Type | Constraints and meaning |
|---|---|---|
| `chore_id` | BIGINT | Required foreign key to `chores`; cascades on delete |
| `user_id` | BIGINT | Required foreign key to `users`; cascades on delete |

There is a unique index on `(chore_id, user_id)` to prevent duplicate
assignments and an index on `user_id` for member-specific lookups. The
application validates that every assigned user belongs to the chore's
household, and that at least one assignee is provided when creating or updating
a chore.

## Relationships and lifecycle

- A household has many chores; deleting the household deletes its chores.
- A chore belongs to its household and creator.
- A chore has many assignees through `chore_assignments`.
- Deleting a chore cascades to its assignment rows.
- Removing an assignment during an update replaces the chore's assignment set
  transactionally with the submitted set.
- The calendar reads `due_at`, `frequency`, and assignments from these tables.
  There is no separate persisted occurrence or completion-history table.

## Recurrence behavior

`NONE` produces one calendar item at `due_at`. `DAILY`, `WEEKLY`, and `MONTHLY`
produce occurrences at the same time of day as the initial due date. Expansion
is limited to the requested calendar range and is calculated when the calendar
is read. There is currently no recurrence end date.

Only chores with a non-null `due_at` can appear in the calendar. For a
user-specific calendar, the service returns chores assigned to that user.

## Current schema source

The authoritative schema is maintained by the Rails migrations and
`db/schema.rb`. Create or update tables through migrations; do not edit the
generated schema by hand.
