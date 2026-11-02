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

    it "rejects an amendment if the parent rule is not approved" do
      unapproved_rule = Rule.create!(
        household: household,
        created_by: creator,
        title: "Proposed Rule",
        description: "Still in voting"
      )

      amendment = Rule.new(
        household: household,
        created_by: member1,
        parent_rule: unapproved_rule,
        title: "Amendment",
        description: "Trying to amend unapproved rule"
      )

      expect(amendment).not_to be_valid
      expect(amendment.errors[:parent_rule]).to include("must be an approved rule to be amended")
    end

    it "rejects amending an amendment proposal directly" do
      amendment1 = Rule.create!(
        household: household,
        created_by: member1,
        parent_rule: approved_rule,
        title: "Amendment 1",
        description: "First amendment"
      )

      nested_amendment = Rule.new(
        household: household,
        created_by: member2,
        parent_rule: amendment1,
        title: "Nested Amendment",
        description: "Trying to amend an amendment"
      )

      expect(nested_amendment).not_to be_valid
      expect(nested_amendment.errors[:parent_rule]).to include("cannot be an amendment itself")
    end

    it "rejects an amendment if parent rule belongs to a different household" do
      other_house = Household.create!(name: "Other House", creator: outsider)
      HouseholdMembership.create!(household: other_house, user: outsider)

      amendment = Rule.new(
        household: other_house,
        created_by: outsider,
        parent_rule: approved_rule,
        title: "Cross-household amendment",
        description: "Tampering"
      )

      expect(amendment).not_to be_valid
      expect(amendment.errors[:parent_rule]).to include("must belong to the same household")
    end
  end

  describe "even-numbered household majority calculations" do
    let(:member3) { User.create!(name: "Dana", email: "dana@example.com", password: "password123") }

    let(:four_member_household) do
      h = Household.create!(name: "Four Person Flat", creator: creator)
      HouseholdMembership.create!(household: h, user: creator)
      HouseholdMembership.create!(household: h, user: member1)
      HouseholdMembership.create!(household: h, user: member2)
      HouseholdMembership.create!(household: h, user: member3)
      h
    end

    it "requires strictly greater than 50% (3 out of 4) to approve" do
      rule = Rule.create!(
        household: four_member_household,
        created_by: creator,
        title: "Internet Policy",
        description: "No torrenting"
      )

      # 1 vote (creator)
      expect(rule.status).to eq("proposed")

      # 2 votes (creator + member1) -> 2 out of 4 is exactly 50%, not majority
      rule.cast_vote!(member1, "approve")
      expect(rule.reload.status).to eq("proposed")

      # 3 votes (creator + member1 + member2) -> 3 out of 4 is majority!
      rule.cast_vote!(member2, "approve")
      expect(rule.reload.status).to eq("approved")
    end

    it "rejects if 2 members reject in a 4-member household" do
      rule = Rule.create!(
        household: four_member_household,
        created_by: creator,
        title: "Party Policy",
        description: "Parties every Friday"
      )

      rule.cast_vote!(member1, "reject")
      expect(rule.reload.status).to eq("proposed")

      # Second rejection makes majority impossible (max approvals possible is 2 of 4)
      rule.cast_vote!(member2, "reject")
      expect(rule.reload.status).to eq("rejected")
    end
  end

  describe "cascading deletes" do
    it "destroys associated rules and votes when a household is destroyed" do
      rule = Rule.create!(
        household: household,
        created_by: creator,
        title: "Temp Rule",
        description: "Will be destroyed"
      )

      expect { household.destroy }.to change(Rule, :count).by(-1)
        .and change(RuleVote, :count).by(-1)
    end
  end
end
