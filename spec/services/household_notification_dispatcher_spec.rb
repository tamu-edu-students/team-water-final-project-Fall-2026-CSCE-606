require "rails_helper"

RSpec.describe HouseholdNotificationDispatcher do
  let!(:admin) do
    User.create!(
      name: "Admin",
      email: "notify-admin@example.com",
      password: "password123"
    )
  end

  let!(:roommate) do
    User.create!(
      name: "Roommate",
      email: "notify-roommate@example.com",
      password: "password123"
    )
  end

  let!(:household) do
    Household.create!(name: "Test House", creator: admin)
  end

  before do
    household.household_memberships.create!(
      user: admin, role: "admin"
    )
    household.household_memberships.create!(
      user: roommate, role: "member"
    )
  end

  let(:expense) do
    Expense.create!(
      household: household,
      created_by: admin,
      title: "Internet",
      amount: 60,
      expense_date: Date.current
    ).tap do |record|
      record.split_equally([ admin.id, roommate.id ])
    end
  end

  let(:chore) do
    Chore.create!(
      household: household,
      creator: admin,
      title: "Clean Kitchen",
      frequency: "NONE"
    ).tap do |record|
      record.chore_assignments.create!(user: roommate)
    end
  end

  it "notifies other expense participants by default" do
    delivery = instance_double(ActionMailer::MessageDelivery)

    expect(HouseholdNotificationMailer)
      .to receive(:expense_added)
      .with(expense, roommate)
      .and_return(delivery)

    expect(delivery).to receive(:deliver_later)

    described_class.expense_created(expense: expense, actor: admin)
  end

  it "respects disabled bill notifications" do
    roommate.create_notification_preference!(email_bills: false)

    expect(HouseholdNotificationMailer)
      .not_to receive(:expense_added)

    described_class.expense_created(expense: expense, actor: admin)
  end

  it "notifies assigned roommates by default" do
    delivery = instance_double(ActionMailer::MessageDelivery)

    expect(HouseholdNotificationMailer)
      .to receive(:chore_assigned)
      .with(chore, roommate)
      .and_return(delivery)

    expect(delivery).to receive(:deliver_later)

    described_class.chore_created(chore: chore, actor: admin)
  end

  it "respects disabled chore notifications" do
    roommate.create_notification_preference!(email_chores: false)

    expect(HouseholdNotificationMailer)
      .not_to receive(:chore_assigned)

    described_class.chore_created(chore: chore, actor: admin)
  end
end
