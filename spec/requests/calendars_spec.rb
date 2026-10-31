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
      "assignee_ids" => [user.id]
    )
  end
end
