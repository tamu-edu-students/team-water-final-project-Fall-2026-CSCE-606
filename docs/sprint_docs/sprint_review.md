## Sprint 1 Review: Foundation & Infrastructure

**Overview:**
Sprint 1 successfully established the technical foundation for Roommate OS, delivering core authentication functionality and development infrastructure. The team completed user registration and login capabilities, set up the CI/CD pipeline with Docker containerization, and implemented automated code quality checks using RuboCop. The sprint delivered the essential groundwork needed to support rapid feature development in subsequent sprints.

**Key Work Presented:**
- **User Authentication System (F-004 - 5 points):** Fully functional user registration, secure login, password reset, and session management
- **Docker & CI/CD Infrastructure (F-023 - 5 points):** Containerized development environment with automated testing pipeline via GitHub Actions
- **Code Quality Framework:** RuboCop integration for automated Ruby code analysis to prevent code quality issues
- **Database Schema:** Initial PostgreSQL setup with models for User, Household, HouseholdMembership, and related entities as per the data model
- **Testing Framework:** RSpec and Cucumber configured for test-first development approach
- **Basic Application Layout:** Responsive navigation and foundation for household dashboard

**Progress Towards Product Goal:**
The sprint achieved its goal of establishing a secure, testable foundation. Progress towards the product goal of "reducing confusion, forgotten responsibilities, and conflicts between roommates" includes:
- ✅ Authentication system ensures secure, personalized household access
- ✅ Infrastructure supports the Definition of Done requirement that "Core functionality does not depend on JavaScript"
- ✅ CI/CD pipeline ensures all future features meet quality standards
- ✅ Database schema ready to support all MVP features (chores, bills, inventory)

**Product Backlog Adjustments:**
Based on Sprint 1 learnings and velocity (10 points completed):
- **Refined Estimates:** Expense management features (F-008, F-009, F-010) may need to be split across Sprint 2 and 3 given the 24-point total
- **Added Items:** 
  - Basic error handling framework (discovered need during authentication implementation)
  - Deployment configuration for staging environment
- **Reprioritized:** Dashboard Integration (F-017) may need to begin earlier to support incremental feature delivery
- **Risk Identified:** "Incorrect Expense Calculations" risk mitigation requires additional unit tests for decimal arithmetic before implementing F-009

The team is well-positioned to begin delivering user-facing features in Sprint 2, with all foundational infrastructure now in place.

## Sprint 2 Review: Core Household Management Features

## Sprint 2 Review: Core Features and Integration

**Review Date:** November 2, 2026  
**Stakeholder:** Professor Philip Ritchey

### Overview

Sprint 2 focused on implementing and integrating the core features of Roommate OS, including household management, expenses, chores, calendar events, household rules, and dashboard functionality.

### Key Work Completed

- **Household Management:** Household creation, invitation codes, joining households, and access restrictions.
- **Expense Management:** Expense CRUD, equal/custom splitting, payment tracking, and balance calculations.
- **Chores & Calendar:** Chore creation, assignments, recurring schedules, and calendar event management.
- **Household Rules:** Rule proposals, majority voting, amendments, and revision history.
- **Dashboard:** Integrated household information, expense summaries, upcoming bills, and scheduled chores.
- **Testing:** Expanded RSpec and Cucumber tests and resolved integration conflicts.

### Testing and Quality Verification

Verified locally on November 2, 2026, after merging US08 and US09 into `main`.

| Metric | Result |
|---|---|
| RSpec | 208 examples, 0 failures |
| Cucumber | 67 scenarios, 367 steps, all passed |
| RSpec Line Coverage | 95.41% |
| Cucumber Line Coverage | 90.73% |
| Combined Line Coverage | 96.61% |
| RuboCop | 106 files, 0 offenses |

All tests passed, and line coverage exceeded the required 90% threshold.

### Professor's Feedback and Team Decisions

During the Sprint Review, the professor provided feedback, and the team identified the following improvements:

1. **Deployment:** Deploy during the next sprint. Explore Heroku and Render first, with AWS as the last option.
2. **Admin & Membership:** The team identified that leaving a household and selecting a replacement admin were not implemented. The team agreed to add member departure functionality and a process to select or vote for a new admin when the current admin leaves.
3. **Invitation Security:** Allow invitation codes to be regenerated or revoked if compromised.
4. **Expense History:** Add detailed expense history showing past expenses, costs, and spending breakdowns.

### Product Backlog Adjustments

Based on the review, the team will prioritize:

- Deploying Roommate OS to the cloud.
- Implementing household member departure and admin succession.
- Adding invitation code regeneration and revocation.
- Improving expense history and summaries.
- Continuing inventory management and remaining feature integration.

### Review Outcome

Sprint 2 delivered functional household management workflows and integrated several major features. The team met the automated testing and line-coverage requirements with zero RuboCop offenses.

The review helped identify missing functionality and establish priorities for the next sprint, particularly deployment, household membership changes, invitation security, and expense transparency.
