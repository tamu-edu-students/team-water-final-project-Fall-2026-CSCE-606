require "rails_helper"

RSpec.describe "Household calendar", type: :request do
  let!(:user) do
    User.create!(
      name: "Test User",
      email: "calendar@example.com",
      password: "password123"
    )
  end
  let!(:household) do
    Household.create!(name: "Apartment 101", creator: user).tap do |record|
      HouseholdMembership.create!(user:, household: record)
    end
  end

  it "returns chore due dates with their assigned members" do
    chore = household.chores.create!(
      creator: user,
      title: "Take out trash",
      due_at: Time.zone.parse("2026-11-03 17:00"),
      frequency: "WEEKLY"
    )
    chore.chore_assignments.create!(user:)
    post login_path, params: { email: user.email, password: "password123" }

    get "/households/#{household.id}/calendar", params: {
      from: "2026-11-01T00:00:00Z",
      to: "2026-11-08T23:59:59Z"
    }

    expect(response).to have_http_status(:ok)
    items = JSON.parse(response.body).fetch("items")
    chore_items = items.select { |item| item["type"] == "chore" }

    expect(chore_items.size).to eq(1)
    expect(chore_items.first).to include(
      "id" => chore.id,
      "name" => "Take out trash",
      "due_at" => "2026-11-03T17:00:00Z",
      "assignee_ids" => [ user.id ]
    )
  end

  it "returns expenses with due dates in the requested date range" do
    expense = household.expenses.create!(
      title: "November utilities",
      amount: "84.50",
      expense_date: Date.new(2026, 11, 1),
      due_date: Date.new(2026, 11, 3),
      created_by: user
    )
    household.expenses.create!(
      title: "Undated expense",
      amount: "10.00",
      expense_date: Date.new(2026, 11, 1),
      created_by: user
    )
    household.expenses.create!(
      title: "Later expense",
      amount: "20.00",
      expense_date: Date.new(2026, 11, 1),
      due_date: Date.new(2026, 11, 9),
      created_by: user
    )
    post login_path, params: { email: user.email, password: "password123" }

    get "/households/#{household.id}/calendar", params: {
      from: "2026-11-01T00:00:00Z",
      to: "2026-11-08T23:59:59Z"
    }

    expect(response).to have_http_status(:ok)
    expense_items = JSON.parse(response.body).fetch("items").select { |item| item["type"] == "expense" }

    expect(expense_items).to contain_exactly(
      include(
        "id" => expense.id,
        "name" => "November utilities",
        "due_at" => expense.due_date.in_time_zone.utc.iso8601,
        "amount" => "84.5"
      )
    )
  end

  it "keeps partially paid expenses but removes fully paid expenses" do
    roommate = User.create!(
      name: "Roommate",
      email: "calendar-roommate@example.com",
      password: "password123"
    )
    household.household_memberships.create!(user: roommate)
    partially_paid = household.expenses.create!(
      title: "Shared utilities",
      amount: "60.00",
      expense_date: Date.new(2026, 11, 1),
      due_date: Date.new(2026, 11, 3),
      created_by: user
    )
    partially_paid.expense_participants.create!(user:, amount_owed: "30.00", payment_status: "paid")
    partially_paid.expense_participants.create!(user: roommate, amount_owed: "30.00", payment_status: "pending")
    fully_paid = household.expenses.create!(
      title: "Paid internet",
      amount: "40.00",
      expense_date: Date.new(2026, 11, 1),
      due_date: Date.new(2026, 11, 4),
      created_by: user
    )
    fully_paid.expense_participants.create!(user:, amount_owed: "40.00", payment_status: "paid")
    post login_path, params: { email: user.email, password: "password123" }

    get "/households/#{household.id}/calendar", params: {
      from: "2026-11-01T00:00:00Z",
      to: "2026-11-08T23:59:59Z"
    }

    expect(response).to have_http_status(:ok)
    expense_names = JSON.parse(response.body).fetch("items")
                            .select { |item| item["type"] == "expense" }
                            .map { |item| item["name"] }
    expect(expense_names).to include("Shared utilities")
    expect(expense_names).not_to include("Paid internet")
  end
end
