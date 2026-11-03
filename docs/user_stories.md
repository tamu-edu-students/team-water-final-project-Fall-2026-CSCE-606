# User Stories - Roommate OS

## US-01: Create household and invite roommates
**As a** user, **so that** everyone can collaborate in a shared living space, **I want to** create a household and invite roommates.

**Acceptance criteria**
- Given I am logged in, when I submit a household name, then the household is created and I am its first member.
- Given a household exists, when I send an invite to an email address, then the invitee receives a link that adds them on acceptance.
- Given an invite link has expired or already been used, when it is opened, then an error message is shown and no one is added.

---

## US-02: Record and split shared expenses
**As a** roommate, **so that** household finances remain transparent, **I want to** record shared expenses, split bills equally or by custom amounts, and track outstanding balances.

**Acceptance criteria**
- Given I enter an expense with an amount and payer, when I choose an equal split, then each roommate's share is calculated automatically.
- Given I choose a custom split, when the amounts do not sum to the total, then the expense is rejected with a validation message.
- Given expenses exist, when I open the balances view, then I see what each roommate owes or is owed.

---

## US-03: Mark bill portion as paid
**As a** roommate, **so that** the household can track outstanding payments, **I want to** mark my portion of a bill as paid.

**Acceptance criteria**
- Given I have an unpaid share, when I mark it paid, then its status updates and my outstanding balance decreases by that amount.
- Given a share is already paid, when I view it, then the mark-as-paid option is disabled.

---

## US-04: Create, assign, and schedule chores
**As a** roommate, **so that** household responsibilities are distributed fairly, **I want to** create, assign, and schedule recurring chores.

**Acceptance criteria**
- Given I create a chore, when I set an assignee and a recurrence (e.g. weekly), then it appears on the assignee's list for each occurrence.
- Given a recurring chore, when I enable rotation, then the assignee changes each cycle across all roommates.
- Given a chore has no assignee or schedule, when I save it, then a validation error is shown.

---

## US-05: Complete a chore
**As a** roommate, **so that** everyone knows the task has been handled, **I want to** mark a chore as completed.

**Acceptance criteria**
- Given a chore is assigned to me, when I mark it complete, then its status and completion time are visible to all roommates.
- Given a recurring chore is completed, when the next cycle starts, then a new open instance is created.

---

## US-06: Shared shopping list and supply tracking
**As a** roommate, **so that** we can coordinate purchases and avoid running out of necessities, **I want to** maintain a shared shopping list and track essential household supplies.

**Acceptance criteria**
- Given I add an item to the list, when any roommate opens it, then the item is visible to them.
- Given a tracked supply falls below its set threshold, when inventory is updated, then it is flagged as low and can be added to the list.
- Given an item is purchased, when I check it off, then it is removed from the active list.

---

## US-07: Track bills and receive reminders
**As a** roommate, **so that** payments are made on time, **I want to** track upcoming and recurring bills and receive reminders.

**Acceptance criteria**
- Given a bill has a due date and recurrence, when I save it, then future occurrences are scheduled automatically.
- Given a bill is due within the reminder window (e.g. 3 days), when the window begins, then roommates with unpaid shares are notified.
- Given a bill is paid in full, when the reminder job runs, then no reminder is sent.

---

## US-08: Household dashboard
**As a** roommate, **so that** I can quickly understand what requires my attention, **I want to** see a dashboard showing chores, bills, inventory alerts, and votes.

**Acceptance criteria**
- Given I log in, when the dashboard loads, then it shows my open chores, unpaid bills, low-stock alerts, and open votes.
- Given I have nothing pending in a category, when the dashboard loads, then that section shows an empty-state message.

---

## US-09: Propose and vote on household rules
**As a** roommate, **so that** household expectations can be discussed clearly, **I want to** propose and vote on a household rule.

**Acceptance criteria**
- Given I submit a rule proposal, when it is saved, then all roommates can see it and vote.
- Given I have already voted, when I try to vote again, then my vote is not counted twice.
- Given all roommates have voted or the voting period ends, when results are tallied, then the outcome is shown as accepted or rejected.

---

## US-10: View reservations and unavailable-slot feedback
**As a** roommate, **so that** I can plan around other roommates' bookings, **I want to** view existing reservations and receive clear feedback when a time slot is unavailable.

**Acceptance criteria**
- Given reservations exist, when I open the reservations view, then I see each booked slot and who reserved it.
- Given I request a slot that overlaps an existing reservation, when I submit, then the booking is rejected with a message naming the conflict.
- Given I request an open slot, when I submit, then the reservation is created.

---

# Additional stories (stretch)

## US-011: External Calendar Integration
**As a** roommate  
**I want to** sync household events with my personal calendar  
**So that** I can manage all commitments in one place  

**Story Points:** 5

**Acceptance Criteria:**
- iCal feed generation for chores and bills
- Google Calendar integration via API
- Selective sync options (chores, bills, or both)
- Real-time updates to external calendars
- Color coding for different event types
- Timezone handling for all members

---

## US-012: Guest Management
**As a** roommate  
**I want to** notify others when I'm having guests over  
**So that** everyone can plan accordingly  

**Acceptance Criteria:**
- Guest visits can be scheduled with date/time
- Number of guests specified
- Other members receive notifications
- Recurring guest schedules supported
- Guest parking information shareable

---

## US-013: Household Rules and Agreements
**As a** roommate  
**I want to** propose and vote on household rules  
**So that** expectations are clear and agreed upon  

**Acceptance Criteria:**
- Rules can be proposed by any member
- Voting mechanism with majority threshold
- Approved rules displayed prominently
- Amendment process available
- History of rule changes tracked

---

## US-014: Shared Document Storage
**As a** roommate  
**I want to** store and access important household documents  
**So that** everyone has access to necessary information  

**Acceptance Criteria:**
- Secure document upload (PDF, images)
- Categories for organization (lease, utilities, etc.)
- Version control for updated documents
- Access permissions by role
- Maximum file size limits enforced

---

## Definition of Done (All Stories)
- A user story or increment is considered complete only when all the following criteria are satisfied
- Acceptance tests (Cucumber) include both happy and sad path scenarios associated with the user story.
- All tests are passing.
- Cucumber acceptance test coverage is at least 90%.
- RSpec unit test coverage is at least 90%.
- Combined test coverage is at least 90%.
- There are zero RuboCop offenses in Models, Controllers, Helpers, and Tests.
- The completed increment is deployed to the production environment.

## Notes
- All stories are independent and can be completed within a single sprint
- Story points based on team velocity of 20-25 points per sprint
- Priority determined by MVP requirements and user value
- Each story includes Cucumber feature files in /features directory
