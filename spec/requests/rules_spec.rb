require "rails_helper"

RSpec.describe "Rules management", type: :request do
  let!(:creator) do
    User.create!(name: "Alice", email: "alice@example.com", password: "password123")
  end

  let!(:member) do
    User.create!(name: "Bob", email: "bob@example.com", password: "password123")
  end

  let!(:outsider) do
    User.create!(name: "David", email: "david@example.com", password: "password123")
  end

  let!(:household) do
    h = Household.create!(name: "Water House", creator: creator)
    HouseholdMembership.create!(household: h, user: creator)
    HouseholdMembership.create!(household: h, user: member)
    h
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "password123" }
  end

  describe "Authentication and Authorization" do
    it "redirects unauthenticated users to the login page" do
      get household_rules_path(household)
      expect(response).to redirect_to(login_path)
    end

    it "redirects non-household members to root with an alert" do
      login_as(outsider)
      get household_rules_path(household)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not a member of this household")
    end
  end

  describe "GET /households/:household_id/rules" do
    it "renders the rules page and lists approved rules and proposals" do
      login_as(creator)

      # Create an approved rule (1 person vote in 2-person house is proposed, so member approves it)
      approved_rule = Rule.create!(
        household: household,
        created_by: creator,
        title: "Quiet Hours",
        description: "10 PM onwards",
        category: "Noise & Quiet Hours"
      )
      approved_rule.cast_vote!(member, "approve")

      # Create an open proposal
      open_proposal = Rule.create!(
        household: household,
        created_by: member,
        title: "Guest Notice",
        description: "Give 24hr notice",
        category: "Guests & Visitors"
      )

      get household_rules_path(household)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Quiet Hours")
      expect(response.body).to include("Guest Notice")
      expect(response.body).to include("Approved House Rules")
      expect(response.body).to include("Active Proposals &amp; Voting")
    end
  end

  describe "GET /households/:household_id/rules/new" do
    it "renders the new rule form" do
      login_as(creator)
      get new_household_rule_path(household)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Propose a Household Rule")
    end
  end

  describe "POST /households/:household_id/rules" do
    it "creates a new rule proposal and redirects to index" do
      login_as(creator)
      post household_rules_path(household), params: {
        rule: {
          title: "Clean Kitchen",
          category: "Cleanliness & Chores",
          description: "Wipe down counters after cooking"
        }
      }

      expect(response).to redirect_to(household_rules_path(household))
      expect(flash[:notice]).to eq("Rule proposal was successfully submitted.")

      new_rule = Rule.last
      expect(new_rule.title).to eq("Clean Kitchen")
      expect(new_rule.created_by).to eq(creator)
      expect(new_rule.approve_votes_count).to eq(1)
    end

    it "renders :new with 422 if invalid" do
      login_as(creator)
      post household_rules_path(household), params: {
        rule: {
          title: "",
          category: "General",
          description: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Please correct the following errors")
    end
  end

  describe "POST /households/:household_id/rules/:id/vote" do
    let!(:proposal) do
      Rule.create!(
        household: household,
        created_by: creator,
        title: "AC Setting",
        description: "Keep AC at 72 degrees"
      )
    end

    it "records the vote and updates status upon majority" do
      login_as(member)
      post vote_household_rule_path(household, proposal), params: { decision: "approve" }

      expect(response).to redirect_to(household_rules_path(household))
      expect(flash[:notice]).to eq("Your vote has been recorded.")
      expect(proposal.reload.status).to eq("approved")
    end

    it "records a reject vote" do
      login_as(member)
      post vote_household_rule_path(household, proposal), params: { decision: "reject" }

      expect(response).to redirect_to(household_rules_path(household))
      expect(flash[:notice]).to eq("Your vote has been recorded.")
      expect(proposal.reload.status).to eq("rejected")
    end

    it "prevents duplicate voting by the same user" do
      login_as(creator) # creator already voted via callback
      post vote_household_rule_path(household, proposal), params: { decision: "approve" }

      expect(response).to redirect_to(household_rules_path(household))
      expect(flash[:alert]).to eq("You have already voted on this proposal.")
    end

    it "prevents voting with invalid decision" do
      login_as(member)
      post vote_household_rule_path(household, proposal), params: { decision: "abstain" }

      expect(response).to redirect_to(household_rules_path(household))
      expect(flash[:alert]).to eq("Invalid vote option.")
    end

    it "prevents voting if proposal is already closed" do
      proposal.update!(status: "approved")
      login_as(member)
      post vote_household_rule_path(household, proposal), params: { decision: "approve" }

      expect(response).to redirect_to(household_rules_path(household))
      expect(flash[:alert]).to eq("Voting on this proposal is already closed.")
    end
  end

  describe "GET /households/:household_id/rules/:id" do
    let!(:approved_rule) do
      r = Rule.create!(
        household: household,
        created_by: creator,
        title: "Trash Schedule",
        description: "Tuesday and Friday"
      )
      r.cast_vote!(member, "approve")
      r
    end

    it "renders rule details and revision history" do
      login_as(creator)
      get household_rule_path(household, approved_rule)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Trash Schedule")
      expect(response.body).to include("Agreement Details")
      expect(response.body).to include("Revision History")
      expect(response.body).to include("Version 1")
    end
  end

  describe "Amendments" do
    let!(:approved_rule) do
      r = Rule.create!(
        household: household,
        created_by: creator,
        title: "Fridge Shelves",
        description: "Shelf 1: Alice, Shelf 2: Bob"
      )
      r.cast_vote!(member, "approve")
      r
    end

    it "renders the amendment form" do
      login_as(member)
      get amend_household_rule_path(household, approved_rule)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Propose an Amendment")
      expect(response.body).to include("Current Agreement")
    end

    it "creates an amendment proposal linked to parent rule" do
      login_as(member)
      post amend_household_rule_path(household, approved_rule), params: {
        rule: {
          description: "Shelf 1: Alice, Shelf 2: Bob, Top Shelf: Shared",
          amendment_reason: "We need space for shared condiments"
        }
      }

      expect(response).to redirect_to(household_rules_path(household))
      expect(flash[:notice]).to eq("Amendment proposal was successfully submitted.")

      amendment = Rule.last
      expect(amendment.parent_rule).to eq(approved_rule)
      expect(amendment.created_by).to eq(member)
      expect(amendment.amendment_reason).to eq("We need space for shared condiments")
    end

    it "renders amend with 422 if amendment is invalid" do
      login_as(member)
      post amend_household_rule_path(household, approved_rule), params: {
        rule: {
          description: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Please correct the following errors")
    end

    it "renders the history page" do
      login_as(member)
      get history_household_rule_path(household, approved_rule)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Version History: Fridge Shelves")
      expect(response.body).to include("Version 1")
    end

    it "redirects with alert when trying to amend an unapproved proposal" do
      unapproved = Rule.create!(
        household: household,
        created_by: creator,
        title: "Proposed Only",
        description: "Not approved"
      )

      login_as(member)
      get amend_household_rule_path(household, unapproved)

      expect(response).to redirect_to(household_rules_path(household))
      expect(flash[:alert]).to eq("Only approved rules can be amended.")

      post amend_household_rule_path(household, unapproved), params: {
        rule: { description: "Trying to amend" }
      }
      expect(response).to redirect_to(household_rules_path(household))
      expect(flash[:alert]).to eq("Only approved rules can be amended.")
    end

    it "prevents accessing rules of another household" do
      other_house = Household.create!(name: "Secret House", creator: outsider)
      HouseholdMembership.create!(household: other_house, user: outsider)

      other_rule = Rule.create!(
        household: other_house,
        created_by: outsider,
        title: "Secret Rule",
        description: "Not for you"
      )

      login_as(creator)
      get household_rule_path(household, other_rule)
      expect(response).to have_http_status(:not_found)
    end
  end
end
