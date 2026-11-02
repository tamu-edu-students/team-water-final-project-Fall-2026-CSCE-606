require "rails_helper"

RSpec.describe RuleVote, type: :model do
  let(:creator) { User.create!(name: "Alice", email: "alice@example.com", password: "password123") }
  let(:member) { User.create!(name: "Bob", email: "bob@example.com", password: "password123") }
  let(:outsider) { User.create!(name: "Eve", email: "eve@example.com", password: "password123") }

  let(:household) do
    h = Household.create!(name: "Rules House", creator: creator)
    HouseholdMembership.create!(household: h, user: creator)
    HouseholdMembership.create!(household: h, user: member)
    h
  end

  let(:rule) do
    Rule.create!(
      household: household,
      created_by: creator,
      title: "Shared TV",
      description: "Book TV time on weekends"
    )
  end

  describe "validations" do
    it "is valid when member votes approve or reject" do
      vote = RuleVote.new(rule: rule, user: member, decision: "approve")
      expect(vote).to be_valid

      vote.decision = "reject"
      expect(vote).to be_valid
    end

    it "rejects invalid decision strings" do
      vote = RuleVote.new(rule: rule, user: member, decision: "maybe")
      expect(vote).not_to be_valid
      expect(vote.errors[:decision]).to include("is not included in the list")
    end

    it "prevents duplicate votes by the same user on the same rule" do
      # creator already has a vote recorded by after_create callback
      duplicate_vote = RuleVote.new(rule: rule, user: creator, decision: "approve")
      expect(duplicate_vote).not_to be_valid
      expect(duplicate_vote.errors[:user_id]).to include("has already voted on this rule")
    end

    it "prevents non-household members from voting" do
      vote = RuleVote.new(rule: rule, user: outsider, decision: "approve")
      expect(vote).not_to be_valid
      expect(vote.errors[:user]).to include("must be a member of this household")
    end
  end
end
