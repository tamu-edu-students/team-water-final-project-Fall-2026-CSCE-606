# User Stories - Roommate OS

### US-001: User Registration and Authentication
**As a** prospective roommate  
**I want to** create a secure account with my personal information  
**So that** I can access the household management system securely  

**Story Points:** 5

**Acceptance Criteria:**
- User can register with email, name, and password
- Email validation is performed
- Password meets security requirements (min 8 chars, 1 number, 1 special)
- User receives confirmation email
- Login/logout functionality works correctly
- Session management is secure
- Password reset functionality is available

---

### US-002: Household Creation
**As a** registered user  
**I want to** create a new household with basic information  
**So that** I can start managing my living space collaboratively  

**Story Points:** 8

**Acceptance Criteria:**
- User can create household with unique name and address
- System generates unique invite code automatically
- Creator becomes household admin
- Household appears in user's dashboard
- Maximum one active household per user
- Household details are editable by admin

---

### US-003: Roommate Invitations
**As a** household admin  
**I want to** invite roommates using a secure invite code  
**So that** only authorized people can join my household  

**Story Points:** 8

**Acceptance Criteria:**
- Admin can generate and share invite codes
- Invite codes expire after 7 days
- New members can join with valid code
- Invalid/expired codes show appropriate error
- Member list updates in real-time
- Email notifications sent to admin when someone joins

---

### US-004: Shared Expense Tracking
**As a** roommate  
**I want to** record and split shared expenses with custom or equal amounts  
**So that** household finances remain transparent and fair  

**Story Points:** 8

**Acceptance Criteria:**
- User can create expense entry with amount, description, date
- Expenses can be split equally or by custom percentages
- System calculates individual balances automatically
- Running balance visible to all members
- Expense history is searchable and filterable
- Decimal calculations are precise to 2 decimal places

---

### US-005: Chore Assignment and Tracking
**As a** roommate  
**I want to** create, assign, and schedule household chores  
**So that** responsibilities are distributed fairly  

**Story Points:** 5

**Acceptance Criteria:**
- Chores can be created with title, description, frequency
- Chores assignable to specific members or rotated
- Recurring chores auto-generate on schedule
- Members can mark chores as complete
- Completion history is tracked
- Overdue chores are highlighted

---

### US-006: Shared Shopping List
**As a** roommate  
**I want to** maintain a shared shopping list for household supplies  
**So that** we can coordinate purchases and avoid running out  

**Story Points:** 5

**Acceptance Criteria:**
- Items can be added with name, quantity, priority
- Low stock alerts configurable per item
- Items marked as purchased update inventory
- Shopping list accessible to all members
- Purchase history tracked by member
- Items can be categorized (groceries, cleaning, etc.)

---

### US-007: Bill Management
**As a** roommate  
**I want to** track recurring bills and payment responsibilities  
**So that** all bills are paid on time  

**Story Points:** 5

**Acceptance Criteria:**
- Bills can be added with amount, due date, frequency
- Automatic splitting by percentage or custom amounts
- Members can mark their portion as paid
- Due date reminders sent 3 days in advance
- Payment history viewable by all
- Recurring bills auto-generate monthly

---

### US-008: Household Dashboard
**As a** roommate  
**I want to** see chores, bills, inventory alerts, and votes on a household dashboard.

**So that** I can quickly understand what requires my attention.

**Story Points:** 5

**Acceptance Criteria:**
- Only signed-in household members can open a household's dashboard.
- Users can choose among their own households; a new user can create or join one.
- Dashboard shows unfinished chores due in the next 7 days and overdue chores.
- The current user's outstanding expense share is displayed with decimal precision.
- Unpaid bills due in the next 5 days and overdue bills are highlighted.
- Inventory at or below its low-stock threshold is listed.
- Open rule proposals that require the current user's vote are listed.
- Each connected module links to its household-scoped management page.
- An empty connected module is distinguished from one that is not available yet.
- The page works without JavaScript and at mobile and desktop widths.

**Delivery:** Foundation in the first agreed sprint; live summaries in the
integration sprint after the corresponding modules merge. The team must set
actual sprint dates in its tracker. No completion date is asserted here.

**Current scope:** Foundation only. See [US08 delivery and integration guide](us08-dashboard.md)
for evidence, remaining dependencies, and the 90% coverage criteria. The recent
activity feed remains a stretch feature from the proposal, pending team agreement.

---

### US-09: Expense Analytics
**As a** roommate  
**I want to** view monthly expense summaries and charts  
**So that** I can understand household spending patterns  

**Story Points:** 3 [1]

**Acceptance Criteria:**
- Monthly spending totals by category
- Individual contribution percentages
- Trend charts for last 6 months
- Export functionality to CSV
- Category-wise breakdown pie charts
- Year-over-year comparisons

---

### US-010: Household Activity Audit
**As a** household admin  
**I want to** view a complete history of household activities  
**So that** I can track changes and resolve disputes  

**Story Points:** 3

**Acceptance Criteria:**
- All actions logged with timestamp and user
- Filterable by date range, user, or action type
- Immutable audit trail
- Export functionality for records
- Search capability within logs
- 90-day retention minimum

---

### US-011: External Calendar Integration
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

## Additional User Stories (Backlog)

### US-012: Guest Management
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

### US-013: Household Rules and Agreements
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

### US-014: Shared Document Storage
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
- Feature functionality implemented per acceptance criteria
- Unit tests written and passing (>80% coverage)
- Integration tests passing
- Authentication/authorization enforced
- Works without JavaScript (progressive enhancement)
- Accessibility requirements met (WCAG 2.1 AA)
- Error handling implemented
- Documentation updated
- Code review completed
- Deployed to staging environment
- Feature demo completed with team

## Notes
- All stories are independent and can be completed within a single sprint
- Story points based on team velocity of 20-25 points per sprint
- Priority determined by MVP requirements and user value
- Each story includes Cucumber feature files in /features directory
