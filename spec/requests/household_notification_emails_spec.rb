require "rails_helper"

RSpec.describe "Household notification emails", type: :request do
  include ActiveJob::TestHelper

  let!(:creator) do
    User.create!(
      name: "Alice",
      email: "email-creator@example.com",
      password: "password123"
    )
  end

  let!(:roommate) do
    User.create!(
      name: "Bob",
      email: "email-roommate@example.com",
      password: "password123"
    )
  end

  let!(:household) do
    Household.create!(
      name: "Notification House",
      creator: creator
    )
  end

  before do
    household.household_memberships.create!(
      user: creator, role: "admin"
    )
    household.household_memberships.create!(
      user: roommate, role: "member"
    )

    ActionMailer::Base.deliveries.clear
    clear_enqueued_jobs

    post login_path, params: {
      email: creator.email,
      password: "password123"
    }
  end

  def create_expense
    post household_expenses_path(household), params: {
      expense: {
        title: "Internet",
        amount: "60.00",
        expense_date: Date.current.to_s
      },
      selected_members: [ creator.id.to_s, roommate.id.to_s ]
    }
  end

  def create_chore
    post household_chores_path(household), params: {
      chore: {
        title: "Clean Kitchen",
        frequency: "NONE",
        assignee_ids: [ roommate.id.to_s ]
      }
    }
  end

  it "emails a roommate when a shared expense is created" do
    perform_enqueued_jobs { create_expense }

    expect(response).to redirect_to(household_path(household))

    emails = ActionMailer::Base.deliveries
    expect(emails.size).to eq(1)
    expect(emails.first.to).to eq([ roommate.email ])
    expect(emails.first.subject).to include("Internet")
    expect(emails.first.body.decoded).to include("$30.00")
  end

  it "does not email a roommate who disabled bill alerts" do
    roommate.create_notification_preference!(email_bills: false)

    perform_enqueued_jobs { create_expense }

    expect(response).to redirect_to(household_path(household))
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "emails a roommate when assigned a new chore" do
    perform_enqueued_jobs { create_chore }

    expect(response).to redirect_to(household_chores_path(household))

    emails = ActionMailer::Base.deliveries
    expect(emails.size).to eq(1)
    expect(emails.first.to).to eq([ roommate.email ])
    expect(emails.first.subject).to include("Clean Kitchen")
  end

  it "does not email a roommate who disabled chore alerts" do
    roommate.create_notification_preference!(email_chores: false)

    perform_enqueued_jobs { create_chore }

    expect(response).to redirect_to(household_chores_path(household))
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "does not send notifications for an invalid chore" do
    post household_chores_path(household), params: {
      chore: {
        title: "Invalid Assignment",
        frequency: "NONE",
        assignee_ids: [ "-1" ]
      }
    }

    expect(ActionMailer::Base.deliveries).to be_empty
    expect(Chore.exists?(title: "Invalid Assignment")).to be(false)
  end
end
