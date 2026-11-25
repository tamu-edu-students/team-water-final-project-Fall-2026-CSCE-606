
require "rails_helper"

RSpec.describe "Household Invitations", type: :request do
  let!(:creator) do
    User.create!(
      name: "Creator",
      email: "creator@example.com",
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

  let!(:household) do
    Household.create!(
      name: "Apartment 101",
      creator: creator
    )
  end

  before do
    household.household_memberships.create!(user: creator)

    post login_path, params: {
      email: roommate.email,
      password: "password123"
    }
  end

  it "lets a roommate join with a valid code" do
    expect {
      post join_household_path,
        params: { invite_code: household.invite_code }
    }.to change(HouseholdMembership, :count).by(1)

    expect(household.users.reload).to include(roommate)
    expect(response).to redirect_to(household_path(household))
  end

  it "rejects an invalid code" do
    expect {
      post join_household_path,
        params: { invite_code: "invalid-code" }
    }.not_to change(HouseholdMembership, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "prevents duplicate membership" do
    household.household_memberships.create!(user: roommate)

    expect {
      post join_household_path,
        params: { invite_code: household.invite_code }
    }.not_to change(HouseholdMembership, :count)
  end

  describe "invite link" do
    let(:invite_link) { join_household_path(code: household.invite_code) }

    it "previews the household and prefills the code" do
      get invite_link

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("You're invited to", "Apartment 101", "1 member")
      expect(Nokogiri::HTML(response.body).at_css("#invite_code")["value"]).to eq(household.invite_code)
    end

    it "warns about an invalid link" do
      get join_household_path(code: "invalid-code")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("This invite link is invalid or has expired.")
      expect(response.body).not_to include("You're invited to")
    end

    it "takes existing members straight to the dashboard" do
      household.household_memberships.create!(user: roommate)

      get invite_link

      expect(response).to redirect_to(household_dashboard_path(household))
    end

    it "brings a logged-out visitor back to the link after logging in" do
      delete logout_path
      get invite_link
      expect(response).to redirect_to(login_path)

      post login_path, params: { email: roommate.email, password: "password123" }

      expect(response).to redirect_to(invite_link)
    end

    it "brings a new user back to the link after signing up" do
      delete logout_path
      get invite_link

      post signup_path, params: {
        user: { name: "New", email: "new@example.com", password: "password123", password_confirmation: "password123" }
      }

      expect(response).to redirect_to(invite_link)
    end
  end
end
