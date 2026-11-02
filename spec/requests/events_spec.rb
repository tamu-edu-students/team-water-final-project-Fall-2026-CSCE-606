require "rails_helper"

RSpec.describe "Events", type: :request do
  let!(:user) do
    User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123"
    )
  end
  let!(:household) do
    Household.create!(name: "Apartment 101", creator: user).tap do |record|
      HouseholdMembership.create!(user:, household: record, role: "admin")
    end
  end

  def login
    post login_path, params: { email: user.email, password: "password123" }
  end

  def event_params(overrides = {})
    {
      name: "House meeting",
      description: "Monthly check-in",
      start_timestamp: "2026-11-03T18:00:00Z",
      end_timestamp: "2026-11-03T19:00:00Z",
      recurring: "NONE",
      attendee_ids: []
    }.merge(overrides)
  end

  describe "POST /households/:household_id/events" do
    it "returns the created event" do
      login

      expect do
        post household_events_path(household), params: event_params, as: :json
      end.to change(Event, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to include(
        "name" => "House meeting",
        "recurring" => "NONE",
        "created_by" => user.id
      )
    end
  end

  describe "PATCH /events/:id" do
    it "returns the updated single event" do
      login
      event = household.events.create!(
        event_params.except(:attendee_ids).merge(creator: user)
      )

      patch event_path(event),
            params: { name: "Updated meeting" },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(
        "event_id" => event.id,
        "name" => "Updated meeting"
      )
    end

    it "returns the updated recurring occurrence" do
      login
      event = household.events.create!(
        event_params(recurring: "DAILY").except(:attendee_ids).merge(creator: user)
      )
      occurrence_start = "2026-11-04T18:00:00Z"

      patch event_path(event, scope: "this", occurrence_start:),
            params: { start_timestamp: "2026-11-04T20:00:00Z", end_timestamp: "2026-11-04T21:00:00Z" },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(
        "event_id" => event.id,
        "original_start" => occurrence_start,
        "start_timestamp" => "2026-11-04T20:00:00Z",
        "end_timestamp" => "2026-11-04T21:00:00Z"
      )
    end
  end
end
