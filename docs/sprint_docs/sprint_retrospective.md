## Sprint 1 Retrospective: Foundation & Infrastructure

**Overview:**
Sprint 1 concluded with successful delivery of core authentication and infrastructure components. The team of 6 members completed 10 story points (F-001: User Authentication - 5 points, F-020: Docker & CI/CD - 5 points), establishing the foundation for Roommate OS. The retrospective identified key learnings about team coordination, technical setup challenges, and process improvements needed for Sprint 2.

**What went well:**
- **Test-First Approach Success:** The team's commitment to implementing a "basic test-first approach" resulted in robust authentication tests that caught several security issues early
- **RuboCop Integration:** Automated Ruby code analysis successfully detected code smells and style violations, improving code quality from the start
- **Definition of Done Adherence:** Team successfully met all criteria including "Core functionality does not depend on JavaScript" for authentication features
- **Docker Setup:** Containerization simplified development environment setup across all 6 team members, reducing "it works on my machine" issues
- **Daily Scrum Communication:** Group messages and GitHub integration kept everyone informed despite different schedules
- **Early Risk Mitigation:** Implementing authentication first addressed the "Security and Data Privacy" risk before handling sensitive household data

**Impactful changes added:**
- **Sprint 2 Backlog Addition:** Add "Database seed script" task to quickly populate test data for development
- **Technical Debt Item:** Create comprehensive testing guide documentation before Sprint 2 begins
- **Definition of Done Update:** Add "Local development setup documented" to prevent future environment issues
- **Sprint Planning Adjustment:** Reduce Sprint 2 commitment from 34 to 25 points based on actual velocity
- **Code Review Process:** Require RuboCop checks to pass before PR approval, enforcing code quality standards

The team is better positioned for Sprint 2 with clearer processes, realistic velocity estimates, and improved technical foundation.

## Sprint 2 Retrospective: Core Household Management Features

**Overview:**

Sprint 2 focused on implementing and integrating the core features of Roommate OS. The team successfully merged household management, shared expenses, chores and calendar events, household rules and voting, inventory management, and dashboard integrations.

### What Went Well

- **Feature Development:** Implemented and merged the major household management workflows, including inventory management (PR #35).
- **Testing and Quality:** RSpec and Cucumber tests passed, with each suite exceeding 90% line coverage in the latest verified inventory PR CI run.
- **Collaboration:** All six members contributed to assigned features using feature branches and pull requests.
- **Integration:** Successfully resolved conflicts between independently developed modules.
- **Code Reviews:** Peer reviews helped identify missing test cases, including household isolation for inventory.

### Challenges Encountered

- **Integration Conflicts:** Combining independently developed features required additional coordination and testing.
- **Sprint Scope:** The number of planned features made prioritization challenging.
- **Incomplete Functionality:** Chore completion tracking, dashboard voting summaries, and configurable low-stock alerts remain unfinished.
- **Deployment:** Production deployment is still pending.
- **Household Membership:** Leaving a household and admin succession have not yet been implemented.

### Improvements for the Next Sprint

- Prioritize production deployment using Heroku or Render.
- Implement household departure and admin succession.
- Add invitation code regeneration and revocation.
- Improve detailed expense history.
- Complete remaining dashboard integrations and chore completion tracking.
- Continue maintaining automated tests, code reviews, and accurate documentation.

### Retrospective Outcome

Sprint 2 resulted in substantial functional progress and successful integration of major features. The team identified deployment, unfinished workflows, and integration planning as the most important areas to address in the next sprint.
 resolving outstanding issues, and preparing Roommate OS for production deployment. The proposed improvements will be finalized following the team's retrospective discussion.
