require "rails_helper"

RSpec.describe "Household roommate removal", type: :request do
  let!(:admin) do
    User.create!(
      name: "Admin",
      email: "admin@example.com",
      password: "password123"
    )
  end

  let!(:roommate) do
    User.create!(
      name: "Roommate",
      email: "roommate@example.com",
      password: "password123"
    )
  end

  let!(:other_member) do
    User.create!(
      name: "Other Member",
      email: "othermember@example.com",
      password: "password123"
    )
  end

  let!(:household) do
    Household.create!(
      name: "Test Household",
      creator: admin
    )
  end

  let!(:admin_membership) do
    household.household_memberships.create!(
      user: admin,
      role: "admin"
    )
  end

  let!(:roommate_membership) do
    household.household_memberships.create!(
      user: roommate,
      role: "member"
    )
  end

  let!(:other_membership) do
    household.household_memberships.create!(
      user: other_member,
      role: "member"
    )
  end

  def login_as(user)
    post login_path, params: {
      email: user.email,
      password: "password123"
    }
  end

  before do
    login_as(admin)
  end

  describe "DELETE /households/:household_id/household_memberships/:id" do
    it "allows an admin to remove a roommate" do
      expect {
        delete household_household_membership_path(
          household, roommate_membership
        )
      }.to change(HouseholdMembership, :count).by(-1)

      expect(response).to redirect_to(household)
      expect(household.users).not_to include(roommate)
    end

    it "regenerates the invitation code after removal" do
      old_code = household.invite_code

      delete household_household_membership_path(
        household, roommate_membership
      )

      expect(household.reload.invite_code).not_to eq(old_code)
      expect(Household.find_by(invite_code: old_code)).to be_nil
    end

    it "prevents a removed roommate from rejoining with the old code" do
      old_code = household.invite_code

      delete household_household_membership_path(
        household, roommate_membership
      )

      login_as(roommate)

      post join_household_path, params: {
        invite_code: old_code
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(household.users.reload).not_to include(roommate)
    end

    it "prevents ordinary members from removing roommates" do
      login_as(other_member)
      old_code = household.invite_code

      delete household_household_membership_path(
        household, roommate_membership
      )

      expect(response).to redirect_to(household)
      expect(household.users.reload).to include(roommate)
      expect(household.reload.invite_code).to eq(old_code)
    end

    it "prevents an admin from removing themselves" do
      delete household_household_membership_path(
        household, admin_membership
      )

      expect(response).to redirect_to(household)
      expect(household.admin?(admin)).to be(true)
    end

    it "prevents removing another admin" do
      roommate_membership.update!(role: "admin")

      delete household_household_membership_path(
        household, roommate_membership
      )

      expect(response).to redirect_to(household)
      expect(household.admin?(roommate)).to be(true)
    end

    it "prevents unauthenticated users from removing roommates" do
      delete logout_path

      delete household_household_membership_path(
        household, roommate_membership
      )

      expect(response).to redirect_to(login_path)
      expect(household.users.reload).to include(roommate)
    end
  end
end
