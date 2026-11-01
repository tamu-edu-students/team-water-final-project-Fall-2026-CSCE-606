## Sprint 1: Foundation & Infrastructure (Weeks 1-2)

**Overview:**
Sprint 1 focuses on establishing the technical foundation, development environment, and core authentication system that will support all future features. This includes setting up the infrastructure needed for continuous integration and deployment.

**Sprint Goal:**
Establish a secure, testable, and deployable application foundation with user authentication and basic project infrastructure to enable rapid feature development in subsequent sprints.

**Sprint Backlog Items:**
- F-004: User Registration & Authentication (5 points)
  - Implement secure user signup, login, password reset
  - Session management and authorization framework
- F-023: Docker & CI/CD Setup (5 points)
  - Containerization for consistent development
  - Automated testing pipeline
  - GitHub Actions configuration
- Basic Rails application structure with RuboCop integration
- Database schema setup for initial data model
- Testing framework setup (RSpec, Cucumber)
- Development environment configuration

**Backlog Work Items:**
- Set up PostgreSQL database with initial migrations
- Configure RuboCop for automated Ruby code analysis
- Create User model with secure password handling
- Implement authentication controllers and views
- Set up Docker containers for development
- Configure CI/CD pipeline with automated tests
- Create basic application layout and navigation
- Write authentication tests to ensure security
- Deploy minimal application to staging environment

---

## Sprint 2: Core Household Management Features (Weeks 3-4)

**Overview:**
Sprint 2 delivers the essential household management features that allow roommates to create households, manage expenses, assign chores, track inventory, and establish house rules through a unified dashboard.

**Sprint Goal:**
Enable complete household operations by implementing creation, expense tracking, chore management, inventory control, and collaborative decision-making features that provide immediate value to roommates.

**Sprint Backlog Items:**
- F-005: Household Creation (8 points)
  - Create households with unique names and invite codes
- F-006: Household Membership Management (8 points)
  - Join via invite codes, role assignment (admin/regular)
- F-007: Basic Dashboard Layout (3 points)
  - Responsive dashboard showing household overview
- F-008: Shared Expense Creation (8 points)
  - Add expenses with descriptions, amounts, dates
- F-009: Expense Splitting Logic (8 points)
  - Equal and custom splits with precise decimal calculations
- F-010: Balance Tracking (8 points)
  - Calculate individual balances and payment history
- F-011: Chore Creation & Assignment (5 points)
  - Create one-off and recurring chores
- F-025: Chore Completion Tracking (5 points)
  - Mark complete, track history, handle recurring schedules
- F-013: Shared Shopping Lists (5 points)
  - Create and manage household shopping lists
- F-014: Inventory Management (5 points)
  - Track quantities, low-stock thresholds, purchase history
- F-018: Household Rules/Agreements (3 points)
  - Propose, vote on, and display household rules

**Backlog Work Items:**
- Create membership join flow with code validation
- Build expense management with custom/equal split algorithms
- Implement precise decimal arithmetic for calculations
- Develop chore assignment and rotation system
- Create shopping list with low-stock alerts
- Build voting mechanism for house rules
- Integrate all features into unified dashboard
- Write comprehensive tests for all features
- Ensure core functionality works without JavaScript

**Note:** Sprint 2 totals 66 story points, which exceeds typical velocity. The team should prioritize household creation (F-002, F-003) and expense management (F-005, F-006, F-007) as the highest priority items, with other features moved to Sprint 3 if needed.