require "rails_helper"

RSpec.describe "Household activity notifications", type: :request do
  include ActiveJob::TestHelper

  let!(:admin) do
    User.create!(
      name: "Alice",
      email: "activity-admin@example.com",
      password: "password123"
    )
  end

  let!(:roommate) do
    User.create!(
      name: "Bob",
      email: "activity-roommate@example.com",
      password: "password123"
    )
  end

  let!(:newcomer) do
    User.create!(
      name: "Charlie",
      email: "activity-newcomer@example.com",
      password: "password123"
    )
  end

  let!(:household) do
    Household.create!(
      name: "Notification House",
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
    clear_enqueued_jobs
  end

  def login_as(user)
    post login_path, params: {
      email: user.email,
      password: "password123"
    }
  end

  def join_household
    login_as(newcomer)

    post join_household_path, params: {
      invite_code: household.invite_code
    }
  end

  def propose_rule
    login_as(admin)

    post household_rules_path(household), params: {
      rule: {
        title: "Quiet Hours",
        category: "Noise & Quiet Hours",
        description: "Keep noise low after 10 PM."
      }
    }
  end

  it "emails existing members when a roommate joins" do
    perform_enqueued_jobs { join_household }

    expect(response).to redirect_to(household)

    recipients = ActionMailer::Base.deliveries.flat_map(&:to)
    expect(recipients).to contain_exactly(
      admin.email,
      roommate.email
    )
    expect(recipients).not_to include(newcomer.email)
  end

  it "respects household activity opt-outs on joining" do
    roommate.create_notification_preference!(
      email_household_activity: false
    )

    perform_enqueued_jobs { join_household }

    recipients = ActionMailer::Base.deliveries.flat_map(&:to)
    expect(recipients).to eq([ admin.email ])
  end

  it "does not send joining emails for invalid codes" do
    login_as(newcomer)

    perform_enqueued_jobs do
      post join_household_path, params: {
        invite_code: "INVALID"
      }
    end

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "emails other members when a rule is proposed" do
    perform_enqueued_jobs { propose_rule }

    expect(response).to redirect_to(household_rules_path(household))

    emails = ActionMailer::Base.deliveries
    expect(emails.size).to eq(1)
    expect(emails.first.to).to eq([ roommate.email ])
    expect(emails.first.subject).to include("Quiet Hours")
  end

  it "respects household activity opt-outs for rules" do
    roommate.create_notification_preference!(
      email_household_activity: false
    )

    perform_enqueued_jobs { propose_rule }

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "does not send emails for invalid rule proposals" do
    login_as(admin)

    perform_enqueued_jobs do
      post household_rules_path(household), params: {
        rule: {
          title: "",
          category: "General",
          description: "Invalid proposal"
        }
      }
    end

    expect(ActionMailer::Base.deliveries).to be_empty
  end
end
