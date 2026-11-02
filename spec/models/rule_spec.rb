require "rails_helper"

RSpec.describe Rule, type: :model do
  let(:creator) do
    User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password123"
    )
  end

  let(:member1) do
    User.create!(
      name: "Bob",
      email: "bob@example.com",
      password: "password123"
    )
  end

  let(:member2) do
    User.create!(
      name: "Charlie",
      email: "charlie@example.com",
      password: "password123"
    )
  end

  let(:outsider) do
    User.create!(
      name: "David",
      email: "david@example.com",
      password: "password123"
    )
  end

  let(:household) do
    h = Household.create!(name: "Rules House", creator: creator)
    HouseholdMembership.create!(household: h, user: creator)
    HouseholdMembership.create!(household: h, user: member1)
    HouseholdMembership.create!(household: h, user: member2)
    h
  end

  describe "validations" do
    it "is valid with required attributes" do
      rule = Rule.new(
        household: household,
        created_by: creator,
        title: "Quiet Hours",
        description: "Quiet hours from 10 PM to 7 AM",
        category: "Noise & Quiet Hours"
      )
      expect(rule).to be_valid
    end

    it "requires a title" do
      rule = Rule.new(
        household: household,
        created_by: creator,
        title: nil,
        description: "Some rule"
      )
      expect(rule).not_to be_valid
      expect(rule.errors[:title]).to include("can't be blank")
    end

    it "requires a title with max 120 chars" do
      rule = Rule.new(
        household: household,
        created_by: creator,
        title: "A" * 121,
        description: "Some rule"
      )
      expect(rule).not_to be_valid
      expect(rule.errors[:title]).to include("is too long (maximum is 120 characters)")
    end

    it "requires a description" do
      rule = Rule.new(
        household: household,
        created_by: creator,
        title: "Valid Title",
        description: nil
      )
      expect(rule).not_to be_valid
      expect(rule.errors[:description]).to include("can't be blank")
    end

    it "requires a valid status" do
      rule = Rule.new(
        household: household,
        created_by: creator,
        title: "Valid Title",
        description: "Valid Description",
        status: "invalid_status"
      )
      expect(rule).not_to be_valid
      expect(rule.errors[:status]).to include("is not included in the list")
    end
  end

  describe "voting and majority threshold" do
    it "auto-records creator's approve vote on creation" do
      rule = Rule.create!(
        household: household,
        created_by: creator,
        title: "Dish Duty",
        description: "Wash dishes within 24 hours"
      )

      expect(rule.approve_votes_count).to eq(1)
      expect(rule.voted_by?(creator)).to be true
      expect(rule.vote_by(creator).decision).to eq("approve")
      # In a 3-member household, majority is 2, so 1 vote leaves it proposed
      expect(rule.status).to eq("proposed")
    end

    it "immediately approves in a 1-member household upon creation" do
      solo_user = User.create!(name: "Solo", email: "solo@example.com", password: "password123")
      solo_house = Household.create!(name: "Solo House", creator: solo_user)
      HouseholdMembership.create!(household: solo_house, user: solo_user)

      rule = Rule.create!(
        household: solo_house,
        created_by: solo_user,
        title: "Solo Rule",
        description: "Clean the kitchen"
      )

      expect(rule.status).to eq("approved")
      expect(rule.approved_at).to be_present
      expect(rule.rule_revisions.count).to eq(1)
      expect(rule.rule_revisions.first.version).to eq(1)
    end

    it "approves the rule when a majority approves" do
      rule = Rule.create!(
        household: household,
        created_by: creator,
        title: "Guest Policy",
        description: "Notify roommates before hosting overnight guests"
      )

      expect(rule.status).to eq("proposed")

      # Second member approves (2 out of 3 = majority threshold reached!)
      success = rule.cast_vote!(member1, "approve")
      expect(success).to be true
      rule.reload

      expect(rule.approve_votes_count).to eq(2)
      expect(rule.status).to eq("approved")
      expect(rule.approved_at).to be_present
      expect(rule.rule_revisions.count).to eq(1)
      expect(rule.rule_revisions.first.version).to eq(1)
    end

    it "rejects the rule when rejections make majority impossible" do
      rule = Rule.create!(
        household: household,
        created_by: creator,
        title: "Early Quiet Hours",
        description: "Quiet hours starting at 7 PM"
      )

      # In a 3-member household, majority is 2. Max rejections allowed is 3 - 2 = 1.
      # When 2 members reject, reject count (2) > max rejections allowed (1) -> rejected!
      rule.cast_vote!(member1, "reject")
      expect(rule.reload.status).to eq("proposed")

      rule.cast_vote!(member2, "reject")
      expect(rule.reload.status).to eq("rejected")
    end

    it "does not allow voting on already approved or rejected rules" do
      rule = Rule.create!(
        household: household,
        created_by: creator,
        title: "Trash Night",
        description: "Take trash out on Tuesdays"
      )
      rule.cast_vote!(member1, "approve")
      expect(rule.reload.status).to eq("approved")

      result = rule.cast_vote!(member2, "reject")
      expect(result).to be false
    end
  end

  describe "amendments and version history" do
    let!(:approved_rule) do
      r = Rule.create!(
        household: household,
        created_by: creator,
        title: "Smoking Policy",
        description: "No smoking anywhere in the house"
      )
      r.cast_vote!(member1, "approve")
      r.reload
    end

    it "creates an amendment proposal linked to parent rule" do
      amendment = Rule.create!(
        household: household,
        created_by: member2,
        parent_rule: approved_rule,
        title: "Amendment: Smoking Policy",
        description: "No smoking in the house or on the balcony",
        amendment_reason: "Second-hand smoke reaches bedroom windows"
      )

      expect(amendment.status).to eq("proposed")
      expect(amendment.parent_rule).to eq(approved_rule)
      expect(amendment.approve_votes_count).to eq(1) # member2's vote
    end

    it "applies the amendment to the parent rule upon majority approval and records version 2" do
      amendment = Rule.create!(
        household: household,
        created_by: member2,
        parent_rule: approved_rule,
        title: "Amendment: Smoking Policy",
        description: "No smoking in the house or on the balcony",
        amendment_reason: "Second-hand smoke reaches bedroom windows"
      )

      # creator approves the amendment (2 out of 3 votes)
      amendment.cast_vote!(creator, "approve")
      amendment.reload
      approved_rule.reload

      expect(amendment.status).to eq("approved")
      expect(approved_rule.description).to eq("No smoking in the house or on the balcony")
      expect(approved_rule.rule_revisions.count).to eq(2)

      v2 = approved_rule.rule_revisions.last
      expect(v2.version).to eq(2)
      expect(v2.proposed_by).to eq(member2)
      expect(v2.description).to eq("No smoking in the house or on the balcony")
      expect(v2.reason).to eq("Second-hand smoke reaches bedroom windows")
    end

    it "leaves the parent rule unchanged if the amendment is rejected" do
      original_description = approved_rule.description

      amendment = Rule.create!(
        household: household,
        created_by: member2,
        parent_rule: approved_rule,
        title: "Amendment: Smoking Policy",
        description: "Smoking allowed everywhere",
        amendment_reason: "Relaxed rules"
      )

      amendment.cast_vote!(creator, "reject")
      amendment.cast_vote!(member1, "reject")
      amendment.reload
      approved_rule.reload

      expect(amendment.status).to eq("rejected")
      expect(approved_rule.description).to eq(original_description)
      expect(approved_rule.rule_revisions.count).to eq(1)
    end
  end
end
