
require "rails_helper"

RSpec.describe "Households", type: :request do
  let!(:user) do
    User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123"
    )
  end

  def login
    post login_path, params: {
      email: user.email,
      password: "password123"
    }
  end

  describe "GET /households" do
    it "redirects unauthenticated users to login" do
      get households_path

      expect(response).to redirect_to(login_path)
    end

    it "shows households for a logged-in user" do
      login

      get households_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My Households")
    end

    it "only lists households the user belongs to" do
      own_household = Household.create!(
        name: "My Apartment",
        creator: user
      )

      HouseholdMembership.create!(
        user: user,
        household: own_household
      )

      other_user = User.create!(
        name: "Other User",
        email: "other@example.com",
        password: "password123"
      )

      other_household = Household.create!(
        name: "Private Apartment",
        creator: other_user
      )

      HouseholdMembership.create!(
        user: other_user,
        household: other_household
      )

      login
      get households_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My Apartment")
      expect(response.body).not_to include("Private Apartment")
    end

    it "shows member counts, roles, and invite links for admins only" do
      roommate = User.create!(name: "Roommate", email: "roommate@example.com", password: "password123")
      admin_home = Household.create!(name: "Admin Home", creator: user)
      admin_home.household_memberships.create!(user:, role: "admin")
      admin_home.household_memberships.create!(user: roommate)
      member_home = Household.create!(name: "Member Home", creator: roommate)
      member_home.household_memberships.create!(user: roommate, role: "admin")
      member_home.household_memberships.create!(user:)

      login

      [ households_path, root_path ].each do |path|
        get path
        items = Nokogiri::HTML(response.body).css(".house-existing-item")
        admin_item, member_item = items.partition { |item| item.text.include?("Admin Home") }.map(&:first)

        expect(admin_item.text).to include("2 members · Admin", "Copy invite link")
        expect(admin_item.at_css("[data-clipboard-text-value]")["data-clipboard-text-value"])
          .to eq(join_household_url(code: admin_home.invite_code))
        expect(admin_item.css("a").map { |a| a["href"] })
          .to eq([ household_dashboard_path(admin_home), household_dashboard_path(admin_home), household_path(admin_home) ])
        expect(member_item.text).to include("2 members · Member")
        expect(member_item.text).not_to include("Copy invite link")
      end
    end
  end

  describe "GET /households/new" do
    it "shows the household creation form" do
      login

      get new_household_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create Your Space")
    end

    it "redirects unauthenticated users to login" do
      get new_household_path

      expect(response).to redirect_to(login_path)
    end
  end

  describe "POST /households" do
    it "creates a household and adds the creator as an admin member" do
      login

      expect {
        post households_path, params: {
          household: { name: "Apartment 101" }
        }
      }.to change(Household, :count).by(1)
       .and change(HouseholdMembership, :count).by(1)

      household = Household.last
      membership = household.household_memberships.first

      expect(household.name).to eq("Apartment 101")
      expect(household.creator).to eq(user)
      expect(membership.user).to eq(user)
      expect(membership.role).to eq("admin")
      expect(household.users).to include(user)
      expect(response).to redirect_to(household_path(household))
    end

    it "generates an invitation code for a new household" do
      login

      post households_path, params: {
        household: { name: "Apartment 101" }
      }

      household = Household.last

      expect(household.invite_code).to be_present
      expect(household.invite_code.length).to be >= 24
    end

    it "rejects a household without a name" do
      login

      expect {
        post households_path, params: {
          household: { name: "" }
        }
      }.not_to change(Household, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not create a membership for an invalid household" do
      login

      expect {
        post households_path, params: {
          household: { name: "" }
        }
      }.not_to change(HouseholdMembership, :count)
    end

    it "does not allow unauthenticated household creation" do
      post households_path, params: {
        household: { name: "Unauthorized Household" }
      }

      expect(response).to redirect_to(login_path)
      expect(Household.exists?(name: "Unauthorized Household")).to be(false)
    end
  end

  describe "GET /households/:id" do
    let!(:household) do
      Household.create!(
        name: "Apartment 101",
        creator: user
      )
    end

    before do
      HouseholdMembership.create!(
        user: user,
        household: household
      )
    end

    it "shows household details to a member" do
      login

      get household_path(household)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Apartment 101")
      expect(response.body).to include("Test User")
    end

    it "shows the invitation code to a household admin" do
  household.household_memberships
           .find_by!(user: user)
           .update!(role: "admin")

  login
  get household_path(household)

  expect(response).to have_http_status(:ok)
  expect(response.body).to include(household.invite_code)
  expect(response.body).to include(join_household_url(code: household.invite_code), "Copy Invite Link")
end

it "hides the invitation code from ordinary members" do
  login
  get household_path(household)

  expect(response).to have_http_status(:ok)
  expect(response.body).not_to include(household.invite_code)
end
    it "does not allow unauthenticated users to view household details" do
      get household_path(household)

      expect(response).to redirect_to(login_path)
    end

    it "does not allow non-members to view household details" do
      other_user = User.create!(
        name: "Other User",
        email: "other@example.com",
        password: "password123"
      )

      other_household = Household.create!(
        name: "Private Household",
        creator: other_user
      )

      HouseholdMembership.create!(
        user: other_user,
        household: other_household
      )

      login

      get household_path(other_household)

      expect(response).to have_http_status(:not_found)
    end
  end
  describe "PATCH /households/:id/regenerate_invite_code" do
    let!(:household) do
      Household.create!(
        name: "Test Household",
        creator: user
      )
    end

    before do
      household.household_memberships.create!(
        user: user,
        role: "admin"
      )
      login
    end

    it "generates a new invitation code" do
      old_code = household.invite_code

      patch regenerate_invite_code_household_path(household)

      expect(response).to redirect_to(household)
      expect(household.reload.invite_code).not_to eq(old_code)
    end

    it "invalidates the previous invitation code" do
      old_code = household.invite_code

      patch regenerate_invite_code_household_path(household)

      expect(Household.find_by(invite_code: old_code)).to be_nil
    end

    it "does not remove existing household members" do
      original_members = household.household_memberships.count

      patch regenerate_invite_code_household_path(household)

      expect(household.household_memberships.count).to eq(original_members)
    end

    it "prevents non-admin members from regenerating codes" do
      household.household_memberships
               .find_by!(user: user)
               .update!(role: "member")

      old_code = household.invite_code

      patch regenerate_invite_code_household_path(household)

      expect(response).to redirect_to(household)
      expect(household.reload.invite_code).to eq(old_code)
    end

    it "prevents unauthenticated users from regenerating codes" do
      delete logout_path

      old_code = household.invite_code

      patch regenerate_invite_code_household_path(household)

      expect(response).to redirect_to(login_path)
      expect(household.reload.invite_code).to eq(old_code)
    end
  end

describe "DELETE /households/:id/leave" do
  let!(:household) do
    Household.create!(
      name: "Test Household",
      creator: user
    )
  end

  let!(:roommate) do
    User.create!(
      name: "Roommate B",
      email: "roommate@example.com",
      password: "password123"
    )
  end

  before do
    household.household_memberships.create!(
      user: user,
      role: "admin"
    )

    household.household_memberships.create!(
      user: roommate,
      role: "member"
    )

    login
  end

  it "transfers admin privileges to the selected roommate" do
    delete leave_household_path(household),
           params: { successor_user_id: roommate.id }

    expect(response).to redirect_to(households_path)
    expect(household.admin?(roommate)).to be(true)
    expect(household.admin?(user)).to be(false)
    expect(household.users).not_to include(user)
    expect(household.creator_id).to eq(user.id)
  end

  it "prevents the last admin from leaving without a successor" do
    delete leave_household_path(household)

    expect(response).to redirect_to(household)
    expect(household.admin?(user)).to be(true)
    expect(household.admin?(roommate)).to be(false)
  end

  it "rejects a successor who is not a household member" do
    outsider = User.create!(
      name: "Outsider",
      email: "outsider@example.com",
      password: "password123"
    )

    delete leave_household_path(household),
           params: { successor_user_id: outsider.id }

    expect(response).to redirect_to(household)
    expect(household.admin?(user)).to be(true)
    expect(household.admin?(outsider)).to be(false)
  end

  it "allows an ordinary member to leave without transferring admin" do
    post login_path, params: {
      email: roommate.email,
      password: "password123"
    }

    delete leave_household_path(household)

    expect(response).to redirect_to(households_path)
    expect(household.users).not_to include(roommate)
    expect(household.admin?(user)).to be(true)
  end

  it "prevents the last household member from leaving" do
    household.household_memberships.find_by!(
      user: roommate
    ).destroy!

    delete leave_household_path(household)

    expect(response).to redirect_to(household)
    expect(household.users).to include(user)
    expect(household.admin?(user)).to be(true)
  end
end
end
