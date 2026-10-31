# RoomateOS

## Technical Documentation (required)
Detailed instructions for taking the code from zero (fresh fork/clone) to deployed
Architectural schemas, e.g. system diagram, class diagram, database diagram

## User Guide (required)
A comprehensive guide on how to use your application, library or software for end-users.

## Architecture Decision Records (recommended)
Captures a single Architectural Decision and its rationale
Consists of title, status, context, decision, and consequences, e.g. "In the context of <use case/user story>, facing <concern> we decided for <option> to achieve <quality>, accepting <downside>."

## Postmortems (optional, as appropriate)
A written record of an incident (e.g. system outage) that describes
The incident's impact
The actions taken to mitigate or resolve the incident
The incident's root cause
Follow-up actions taken to prevent the incident from happening again

## Debug Pointers (optional, as appropriate)
Useful information for a developer trying to debug a piece of code, e.g. solutions or workarounds already tried, tries in attempting a fix that did not work


## Current Implementation

Roommate OS is a web-based application designed to help roommates
manage their shared household responsibilities.

The application is being developed using Ruby on Rails and PostgreSQL.

### Implemented Features

#### User Authentication
- User registration with name, email, and password
- Secure password hashing using bcrypt
- User login and logout
- Session-based authentication
- Protected pages accessible only to authenticated users

#### Household Management
- Create a household with a custom name
- Automatically add the creator as a household member
- View households associated with the logged-in user
- View household details and members
- Restrict household access to authorized members

#### Household Invitations
- Generate a unique invitation code for each household
- Allow existing members to share invitation codes
- Join a household using a valid code
- Prevent duplicate household memberships
- Display appropriate errors for invalid invitation codes

### Household Permissions

All household members have equal permissions.

There are no admin or privileged member roles. The person who
creates a household has the same household permissions as any
roommate who joins using an invitation code.

### Technology Stack

- Ruby 3.4.10
- Ruby on Rails 8.1.4
- PostgreSQL
- RSpec for automated model and request testing
- Cucumber for acceptance testing
- SimpleCov for code coverage

### Running the Application

Install dependencies:

```bash
bundle install
```

Prepare the database:

```bash
bin/rails db:prepare
```

Start the Rails server:

```bash
bin/rails server
```

Open http://localhost:3000.

### Running Tests

Run the RSpec suite:

```bash
bundle exec rspec
```

Run the Cucumber acceptance tests:

```bash
bundle exec cucumber --publish-quiet
```

RSpec coverage reports are generated under `coverage/`.

### Current Development Status

US01 — Household Creation & Invitations has been implemented
and verified through automated and manual testing.

The US08 dashboard foundation provides a household selector after login and a
member-only overview at `/households/:household_id/dashboard`. It displays the
household's actual members and clearly identifies the four summaries that are
not integrated yet. No balances, chore counts, inventory alerts, or votes are
fabricated. See [the US08 guide](docs/us08-dashboard.md) for the user guide,
integration checklist, architecture, and remaining delivery requirements.

RSpec and Cucumber produce separate reports at `coverage/rspec/index.html`
and `coverage/cucumber/index.html`. After running both suites, generate the
combined report with `bundle exec ruby script/coverage_report.rb`.
