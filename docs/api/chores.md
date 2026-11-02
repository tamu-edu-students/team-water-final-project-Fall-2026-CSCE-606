# Chore Management Routes

Chores are managed through authenticated HTML pages and forms nested under a
household. They are separate records from calendar events. The calendar reads
dated chores and expands their recurrence at request time.

## Conventions and permissions

- A user must be signed in and a member of the household for all chore routes.
- Household membership is used to scope the household and chore lookup.
- The household creator is an admin. A household admin or the chore creator may
  edit or delete the chore.
- The user creating a chore is stored as its creator.
- Assignments must contain one or more users who are members of the same
  household.
- These routes render HTML and use redirect/flash messages; they are not JSON
  endpoints.

## Routes

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/households/{household_id}/chores` | List chores and show the create form |
| `POST` | `/households/{household_id}/chores` | Create a chore and assignments |
| `GET` | `/households/{household_id}/chores/{id}/edit` | Show the edit form (admin or creator) |
| `PATCH` / `PUT` | `/households/{household_id}/chores/{id}` | Update chore and assignments (admin or creator) |
| `DELETE` | `/households/{household_id}/chores/{id}` | Delete chore and assignments (admin or creator) |

The household dashboard's Chores card links to the list page. The create form
is on that page; Edit opens a separate full-page form.

## Form fields

Forms submit fields under `chore`:

| Field | Required | Details |
|---|---|---|
| `title` | Yes | Up to 200 characters |
| `description` | No | Free-form text |
| `due_at` | No | Due date and time; submitted using the browser's local datetime field |
| `frequency` | Yes | `NONE`, `DAILY`, `WEEKLY`, or `MONTHLY`; defaults to `NONE` |
| `assignee_ids[]` | Yes | One or more household member IDs |

**Create example**

```http
POST /households/12/chores
Content-Type: application/x-www-form-urlencoded

chore[title]=Clean+Kitchen&
chore[description]=Wipe+counters&
chore[due_at]=2026-11-03T18%3A00&
chore[frequency]=WEEKLY&
chore[assignee_ids][]=7&
chore[assignee_ids][]=8
```

Successful create, update, and delete operations redirect to the household
chores page with a confirmation message. Invalid input redirects to that page
or the edit page with an error message. Requests for a household or chore the
user cannot access return not found. Unauthorized edit/delete attempts redirect
to the chores page with an authorization message and do not modify the chore.

## Calendar integration

`GET /households/{household_id}/calendar?from={ISO8601}&to={ISO8601}` includes
dated chores assigned to household members. Each chore item has `type: "chore"`,
the chore ID, name, due timestamp, and `assignee_ids`. The household endpoint
returns chores assigned within that household; the all-households calendar page
filters chores to those assigned to the logged-in user. Chores without a due
date are excluded. Recurring due dates are expanded for the requested range;
no event or occurrence rows are created for them.

Bill management is not implemented. The calendar service accepts other
timestamped item types for future integrations.

## Deletion behavior

Deleting a chore removes its `chore_assignments` rows through the database
cascade. It also removes that chore from future calendar reads. Deletion is
permanent; there is no soft-delete or undo flow.
