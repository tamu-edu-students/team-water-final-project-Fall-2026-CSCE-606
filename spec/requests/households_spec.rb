
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
  end

  describe "GET /households/new" do
    it "shows the household creation form" do
      login

      get new_household_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create a Household")
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

    it "shows the invitation code to a household member" do
      login

      get household_path(household)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(household.invite_code)
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
end
