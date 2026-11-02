# Calendar Module API

Part of **Roommate OS**. The calendar is an in-app shared calendar for a household. It shows custom events and chore due dates. The service can accept additional timestamped item types for future integrations; bill management is not implemented.

External calendar sync (Google/Apple) is out of scope for the MVP. See `../db/events.md` for the event database design and `../db/chores.md` for the chore database design.

## Conventions

- **Auth:** Every endpoint requires a logged-in user. The user is taken from the session, never from the URL.
- **Authorization:** The caller must be a member of the household that owns the resource. Editing or deleting an event is limited to its creator or a household admin.
- **Format:** JSON request and response bodies (`Content-Type: application/json`).
- **Timestamps:** ISO 8601 in UTC, e.g. `2026-11-03T18:00:00Z`.
- **Recurrence:** `recurring` is one of `NONE`, `DAILY`, `WEEKLY`, `MONTHLY`. An optional `recurrence_until` date ends the series. Occurrences are expanded at read time, not stored.

## Event object

| Field | Type | Notes |
|---|---|---|
| `event_id` | integer | Read-only |
| `household_id` | integer | Read-only |
| `name` | string | Required |
| `description` | string | Optional |
| `start_timestamp` | timestamp | Required |
| `end_timestamp` | timestamp | Required, must be after `start_timestamp` |
| `all_day` | boolean | Default `false` |
| `recurring` | string | `NONE` (default), `DAILY`, `WEEKLY`, `MONTHLY` |
| `recurrence_until` | date \| null | Optional end of the series. Only valid when `recurring` is not `NONE` |
| `attendee_ids` | integer[] | Household members involved. Empty means the whole household |
| `created_by` | integer | Read-only, user id of the creator |

Occurrences returned by the list endpoints also include `original_start`. It is the start time the series rule generated for that occurrence, and it identifies the occurrence in update and delete calls. For a single (non-recurring) event it equals `start_timestamp`.

---

## Endpoints

### 1. Get combined calendar

`GET /households/{hid}/calendar?from=&to=`

Returns events and chore due dates for the date range, and supports additional timestamped calendar item types for future integrations. Chores are read from their own table, not copied into events. Recurring events and chore due dates are expanded at read time, with single-occurrence event edits and deletions applied.

| Query param | Required | Description |
|---|---|---|
| `from` | yes | Range start (timestamp) |
| `to` | yes | Range end (timestamp) |

**200 OK**
```json
{
  "items": [
    { "type": "event", "event_id": 12, "original_start": "2026-11-03T18:00:00Z", "name": "House meeting", "start_timestamp": "2026-11-03T18:00:00Z", "end_timestamp": "2026-11-03T19:00:00Z" },
    { "type": "chore", "id": 4, "name": "Take out trash", "due_at": "2026-11-04T17:00:00Z", "assignee_ids": [7] },
    { "type": "bill", "id": 9, "name": "Electricity", "due_at": "2026-11-05T00:00:00Z", "amount": "84.50" }
  ]
}
```

---

### 2. List events

`GET /households/{hid}/events?from=&to=&user_id=`

Returns events only. Recurring events are expanded within the range, with single-occurrence edits applied and cancelled occurrences left out.

| Query param | Required | Description |
|---|---|---|
| `from` | yes | Range start |
| `to` | yes | Range end |
| `user_id` | no | Only events that include this member. Omit for all household events |

**200 OK**
```json
{
  "events": [
    {
      "event_id": 12,
      "household_id": 1,
      "name": "House meeting",
      "description": "Monthly check-in",
      "start_timestamp": "2026-11-03T18:00:00Z",
      "end_timestamp": "2026-11-03T19:00:00Z",
      "original_start": "2026-11-03T18:00:00Z",
      "all_day": false,
      "recurring": "MONTHLY",
      "recurrence_until": null,
      "attendee_ids": [],
      "created_by": 7
    }
  ]
}
```

---

### 3. Create event

`POST /households/{hid}/events`

Creates a single or recurring event. Attendees must be members of the household. No accept step is needed.

**Request**
```json
{
  "name": "House meeting",
  "description": "Monthly check-in",
  "start_timestamp": "2026-11-03T18:00:00Z",
  "end_timestamp": "2026-11-03T19:00:00Z",
  "all_day": false,
  "recurring": "MONTHLY",
  "recurrence_until": "2027-05-03",
  "attendee_ids": [7, 8]
}
```

**201 Created**: returns the event object.

---

### 4. Update event

`PATCH /events/{id}?scope=this|all`

Partial update. Send only the fields to change.

| Query param | Required | Description |
|---|---|---|
| `scope` | no | `all` (default) changes the whole series. `this` changes one occurrence only |
| `occurrence_start` | when `scope=this` | The `original_start` of the occurrence to change |

- **`scope=all`:** Updates the event row. Existing single-occurrence changes are kept.
- **`scope=this`:** Saves the changed fields as an override for that occurrence only. Only `name`, `description`, `start_timestamp` and `end_timestamp` can be changed this way. Changing `recurring`, `recurrence_until` or `attendee_ids` with `scope=this` returns 400.
- For a single (non-recurring) event, `scope` is ignored.

**Request** (`scope=this`, move one occurrence)
```json
{ "start_timestamp": "2026-11-04T18:00:00Z", "end_timestamp": "2026-11-04T19:00:00Z" }
```

**200 OK**: returns the updated event, or the updated occurrence when `scope=this`.

---

### 5. Delete event

`DELETE /events/{id}?scope=this|all`

| Query param | Required | Description |
|---|---|---|
| `scope` | no | `all` (default) deletes the whole series. `this` removes one occurrence only |
| `occurrence_start` | when `scope=this` | The `original_start` of the occurrence to remove |

For a single (non-recurring) event, `scope` is ignored and the event is deleted.

**204 No Content**

---

## Errors

| Status | When |
|---|---|
| 400 | Invalid body or params (e.g. `end_timestamp` before `start_timestamp`, missing `from`/`to`, missing `occurrence_start` with `scope=this`, `occurrence_start` that isn't an occurrence of the series, series-level field changed with `scope=this`) |
| 401 | Not logged in |
| 403 | Not a member of the household, or not the creator or an admin for update/delete |
| 404 | Household or event not found |

**Error body**
```json
{ "error": "end_timestamp must be after start_timestamp" }
```

## Not in the MVP

- Linking Google or Apple calendars
- Email invites and RSVP/accept flow for events (can be added later with a status column on `event_attendees`)
- "This and all following occurrences" edits
- Different attendees for a single occurrence