## Daily Scrum 1 — October 20, 2026

**Scrum:** Sprint 2 — Feature Planning and Task Distribution

**Time:** team discussion, beginning at 4:10 PM

**Attendance:** Wyatt, Aditi, Vasanth, Bhaumik, Aditya, Dheeraj (participants in the discussion)

**Overview:**
Aditi added the initial application setup and foundational implementation to serve as the basis for further feature development. The team discussed and prioritized MVP features ahead of the mid-project deadline, distributed user stories among all six members, and agreed to use separate feature branches to support parallel development and smoother integration.

User stories were assigned as follows:
- Aditi — US01: Household Creation & Invitations
- Bhaumik — US08: Household Dashboard
- Wyatt — US02: Shared Expense Management
- Aditya — US04: Chore Management
- Vasanth — US06: Inventory & Shopping List
- Dheeraj — US09: House Rules & Voting

The team also discussed creating a simple landing page to provide a consistent starting point for the application.

**Actionable plan:**

- Begin implementation of assigned user stories on separate branches.
- Move prioritized features into the Sprint Backlog.
- Coordinate shared interfaces and dependencies before integration.
- Establish a simple landing page and connect completed features through the household dashboard.

---

## Daily Scrum 2 — October 23, 2026

**Scrum:** Sprint 2 — Authentication and Shared Module Integration

**Time:** team updates, 7:49 AM–6:49 PM

**Attendance:** Aditi, Aditya, Bhaumik (participants in the discussion)

**Overview:**

The team reviewed progress on the application's foundational household functionality and identified dependencies between user stories.

Aditi completed the initial US01 implementation, including user authentication, household creation, and invitations. The team agreed to merge US01 into `main` so that other features could use the existing authentication and household models.

Aditya began developing a common calendar module intended to support chores, events, and potentially bills. The team discussed sharing API documentation and ensuring the authenticated user's ID remained accessible through the session.

GitHub repository access was also coordinated to support collaboration.

**Actionable plan:**

- Merge US01 into `main` to provide a shared foundation.
- Ensure authenticated user information is stored in the Rails session.
- Continue development of the shared calendar APIs and documentation.
- Integrate upcoming features with the existing household and authentication workflows.

---

## Daily Scrum 3 — October 25, 2026

**Scrum:** Sprint 2 — Feature Progress and Role Permissions

**Time:** team updates, beginning at 7:23 PM

**Attendance:** Aditi, Wyatt, Aditya (participants in the discussion)

**Overview:**

The team discussed progress on expense management and calendar/chore development.

Wyatt reported that US02 was nearly complete and undergoing testing. During review of the calendar implementation, the team identified a design question concerning household administrator permissions.

The discussion focused on whether household creators should receive special privileges and how to align role management with the project's authorization requirements.

**Actionable plan:**

- Complete testing for shared expense management.
- Clarify administrator and member authorization requirements.
- Coordinate the calendar module with existing household membership functionality.
- Continue reviewing feature dependencies before integration.

---

## Daily Scrum 4 — October 27, 2026

**Scrum:** Sprint 2 — Expense Readiness and Authorization Design

**Time:** team updates, beginning 8:08 AM

**Attendance:** Aditi, Aditya, Wyatt (participants in the discussion)

**Overview:**

The team continued discussing household role permissions. Aditi suggested keeping the creator's administrator role nominal to preserve fairness among roommates, while Aditya proposed allowing administrators to manage shared scheduled events.

Wyatt reported completion of the US02 shared expense implementation and requested guidance on whether to merge it immediately or wait for dashboard integration.

This revealed dependencies between expense management, household roles, and the dashboard.

**Actionable plan:**

- Finalize administrator and member permission behavior.
- Coordinate the merge sequence for expenses and dashboard functionality.
- Prepare shared expense functionality for code review and integration.
- Ensure household authorization rules remain consistent across modules.

---

## Daily Scrum 5 — October 28, 2026

**Scrum:** Sprint 2 — Dashboard and Expense Integration

**Time:** Asynchronous team updates, 10:33 AM–11:41 PM

**Attendance:** Aditi, Wyatt, Bhaumik (participants in the discussion)

**Overview:**

The team clarified that administrators could manage certain household items while individual creators retained permission to edit their own items, addressing earlier confusion about role privileges.

Bhaumik opened PR #29 for the household dashboard foundation, connecting authentication and household membership with the dashboard. The implementation passed 52 RSpec examples and 18 Cucumber scenarios locally.

Wyatt reviewed and merged the dashboard PR and coordinated the integration of shared expenses. The team agreed that US02 could be integrated directly with the dashboard rather than waiting for every other module to be completed.

The shared expense PR was subsequently submitted for review.

**Actionable plan:**

- Review the shared expense PR and its integration tests.
- Connect expense balances and pending payments to the household dashboard.
- Verify that the dashboard displays information for the authenticated user and selected household.
- Continue integrating modules incrementally as they become available.

---

## Daily Scrum 6 — October 31, 2026

**Scrum:** Sprint 2 — Calendar and Chore Module Review

**Time:** team update, 12:44 PM

**Attendance:** Aditya (recorded update)

**Overview:**

Aditya reported completing the calendar and chore-management modules, including the calendar interface and chore integration.

Following earlier review feedback, updates were made to the calendar implementation, and PR #27 was retargeted to `main` for integration with the shared application.

The module introduced household administrator and member roles, with the household creator assigned the administrator role by default. Further integration and review were still required.

**Actionable plan:**

- Review PR #27 for calendar and chore functionality.
- Verify integration with existing household membership and authentication code.
- Check authorization behavior and regression tests.
- Resolve outstanding issues before merging the changes into the main application.

---

## Daily Scrum 7 — November 1, 2026

**Scrum:** Sprint 2 — Integration and Mid-Review Preparation

**Time:** team updates, 2:00 PM– 3:00 PM

**Attendance:** Wyatt, Aditi, Aditya, Bhaumik (participants in the discussion)

**Overview:**

The team shifted attention toward completing the required mid-project deliverables while continuing feature integration.

Wyatt added submission documentation and recommended prioritizing deliverables once calendar and chore integration was resolved. Aditi also updated project documentation and identified remaining Scrum documentation work.

Aditya requested final review of PR #27. Bhaumik opened PR #33 to integrate chores and calendar functionality with the existing expense dashboard, reporting that CI checks were passing.

Wyatt approved PR #33 and recommended postponing incomplete inventory and voting integration until after the immediate submission requirements were addressed.

**Actionable plan:**

- Complete review and integration of PR #33.
- Avoid duplicating PR #27 changes when merging the combined integration branch.
- Prioritize required Scrum artifacts, testing evidence, and project documentation.
- Defer unfinished optional integration work until after the immediate submission deadline.
- Coordinate remaining inventory and voting module dependencies.

---

## Daily Scrum 8 — November 2, 2026

**Scrum:** Sprint 2 — Household Rules and Final Submission Readiness

**Time:** team update, 2:01 AM

**Attendance:** Dheeraj (recorded update)

**Overview:**

Dheeraj reported completing US09 Household Rules & Agreements and opening a pull request for review.

The implementation includes household rule proposals, majority-based voting, amendments, version history, and five user-interface views.

The update adds another feature ready for review as the team approaches its mid-project submission deadline. The team still needs to verify integration readiness and prioritize the required deliverables.

**Actionable plan:**

- Review the US09 pull request and provide feedback.
- Verify whether the module can be integrated without delaying submission.
- Complete outstanding Sprint documentation and testing evidence.
- Confirm the status of incomplete features and prepare the mid-project submission.
