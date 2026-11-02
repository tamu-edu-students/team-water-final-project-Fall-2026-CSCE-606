require "rails_helper"

RSpec.describe RuleRevision, type: :model do
  let(:creator) { User.create!(name: "Alice", email: "alice@example.com", password: "password123") }
  let(:household) do
    h = Household.create!(name: "Rules House", creator: creator)
    HouseholdMembership.create!(household: h, user: creator)
    h
  end

  let(:rule) do
    Rule.create!(
      household: household,
      created_by: creator,
      title: "Clean Kitchen",
      description: "Clean kitchen every night"
    )
  end

  it "is valid with required attributes" do
    revision = RuleRevision.new(
      rule: rule,
      proposed_by: creator,
      description: "Clean counters and wash dishes",
      version: 1
    )
    expect(revision).to be_valid
  end

  it "requires a description" do
    revision = RuleRevision.new(
      rule: rule,
      proposed_by: creator,
      description: nil,
      version: 1
    )
    expect(revision).not_to be_valid
    expect(revision.errors[:description]).to include("can't be blank")
  end

  it "requires a version >= 1" do
    revision = RuleRevision.new(
      rule: rule,
      proposed_by: creator,
      description: "Desc",
      version: 0
    )
    expect(revision).not_to be_valid
    expect(revision.errors[:version]).to include("must be greater than or equal to 1")
  end
end
