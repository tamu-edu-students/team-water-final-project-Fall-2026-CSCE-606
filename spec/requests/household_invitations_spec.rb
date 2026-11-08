require "rails_helper"

RSpec.describe "Household email invitations", type: :request do
  let!(:admin) do
    User.create!(
      name: "Admin",
      email: "invitation-admin@example.com",
      password: "password123"
    )
  end

  let!(:roommate) do
    User.create!(
      name: "Roommate",
      email: "invitation-member@example.com",
      password: "password123"
    )
  end

  let!(:household) do
    Household.create!(
      name: "Test Apartment",
      creator: admin
    )
  end

  before do
    household.household_memberships.create!(
      user: admin, role: "admin"
    )
    household.household_memberships.create!(
      user: roommate, role: "member"
    )

    ActionMailer::Base.deliveries.clear
  end

  def login_as(user)
    post login_path, params: {
      email: user.email,
      password: "password123"
    }
  end

  def send_invitation(email)
    post household_invitation_path(household),
         params: { email: email }
  end

  describe "POST /households/:household_id/invitation" do
    it "allows an admin to send an invitation" do
      login_as(admin)

      expect {
        send_invitation("newroommate@example.com")
      }.to change(ActionMailer::Base.deliveries, :count).by(1)

      expect(response).to redirect_to(household)
    end

    it "includes the correct household details and invitation code" do
      login_as(admin)

      send_invitation("newroommate@example.com")

      email = ActionMailer::Base.deliveries.last

      expect(email.to).to eq([ "newroommate@example.com" ])
      expect(email.subject).to include("Test Apartment")
      expect(email.body.decoded).to include(
        household.invite_code,
        household.name,
        admin.name,
        "/join-household"
      )
    end

    it "prevents ordinary members from sending invitations" do
      login_as(roommate)

      expect {
        send_invitation("someone@example.com")
      }.not_to change(ActionMailer::Base.deliveries, :count)

      expect(response).to redirect_to(household)
    end

    it "prevents unauthenticated users from sending invitations" do
      expect {
        send_invitation("someone@example.com")
      }.not_to change(ActionMailer::Base.deliveries, :count)

      expect(response).to redirect_to(login_path)
    end

    it "rejects invalid email addresses" do
      login_as(admin)

      expect {
        send_invitation("invalid-email")
      }.not_to change(ActionMailer::Base.deliveries, :count)

      expect(response).to redirect_to(household)
    end

    it "rejects blank email addresses" do
      login_as(admin)

      expect {
        send_invitation("")
      }.not_to change(ActionMailer::Base.deliveries, :count)

      expect(response).to redirect_to(household)
    end

    it "does not invite existing household members" do
      login_as(admin)

      expect {
        send_invitation(roommate.email)
      }.not_to change(ActionMailer::Base.deliveries, :count)

      expect(response).to redirect_to(household)
    end

    it "normalizes email addresses before sending" do
      login_as(admin)

      send_invitation("  NEWROOMMATE@EXAMPLE.COM  ")

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to eq([ "newroommate@example.com" ])
    end

    it "prevents outsiders from sending invitations" do
      outsider = User.create!(
        name: "Outsider",
        email: "invitation-outsider@example.com",
        password: "password123"
      )

      login_as(outsider)

      expect {
        send_invitation("someone@example.com")
      }.not_to change(ActionMailer::Base.deliveries, :count)

      expect(response).to have_http_status(:not_found)
    end
    it "handles email delivery failures gracefully" do
      login_as(admin)

      allow(HouseholdInvitationMailer).to receive(:invite)
        .and_raise(Errno::ECONNREFUSED)

      send_invitation("newroommate@example.com")

      expect(response).to redirect_to(household)
      expect(flash[:alert]).to include("Unable to send invitation")
      expect(flash[:notice].to_s).not_to include(
        "Invitation email processed successfully"
      )
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end
end
