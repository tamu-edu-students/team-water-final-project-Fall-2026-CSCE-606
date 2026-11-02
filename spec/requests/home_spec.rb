require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "redirects unauthenticated users to login" do
      get root_path

      expect(response).to redirect_to(login_path)
    end

    it "allows authenticated users to view the homepage" do
      user = User.create!(
        name: "Test User",
        email: "test@example.com",
        password: "password123"
      )

      post login_path, params: {
        email: user.email,
        password: "password123"
      }

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Welcome to Roommate OS!")
    end

    it "shows events from all of the user's households on the calendar page" do
      user = User.create!(
        name: "Test User",
        email: "test@example.com",
        password: "password123"
      )
      other_member = User.create!(
        name: "Other Member",
        email: "other@example.com",
        password: "password123"
      )
      households = ["Apartment 101", "Apartment 202"].map do |name|
        Household.create!(name:, creator: user).tap do |household|
          HouseholdMembership.create!(user:, household:)
          HouseholdMembership.create!(user: other_member, household:)
        end
      end
      event_attributes = {
        start_timestamp: Time.zone.parse("2026-11-12 18:00"),
        end_timestamp: Time.zone.parse("2026-11-12 19:00"),
        recurring: "NONE"
      }
      event = households.first.events.create!(
        event_attributes.merge(creator: user, name: "Dinner with me")
      )
      event.event_attendees.create!(user:)
      households.second.events.create!(
        event_attributes.merge(creator: user, name: "Whole household dinner")
      )
      event = households.first.events.create!(
        event_attributes.merge(creator: user, name: "Other member only")
      )
      event.event_attendees.create!(user: other_member)
      chore = households.first.chores.create!(
        creator: user,
        title: "Take out trash",
        due_at: Time.zone.parse("2026-11-12 17:00"),
        frequency: "WEEKLY"
      )
      chore.chore_assignments.create!(user:)

      post login_path, params: { email: user.email, password: "password123" }
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Dinner with me", "Whole household dinner")
      expect(response.body).to include("Open calendar", "dashboard-nav-icon")

      get calendar_path, params: { month: "2026-11" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Your calendar", "November 2026", "Dinner with me")
      expect(response.body).to include("Whole household dinner", "Apartment 202", "Take out trash", "Chore")
      expect(response.body).not_to include("Other member only")
    end

    it "requires a login to open the calendar" do
      get calendar_path

      expect(response).to redirect_to(login_path)
    end

    it "renders additional calendar item types in the calendar UI" do
      user = User.create!(
        name: "Calendar User",
        email: "calendar-user@example.com",
        password: "password123"
      )
      household = Household.create!(name: "Apartment 303", creator: user)
      HouseholdMembership.create!(user:, household:)
      post login_path, params: { email: user.email, password: "password123" }
      allow_any_instance_of(CalendarService).to receive(:calendar_items_for).and_wrap_original do |original, record, **options|
        original.call(
          record,
          **options,
          additional_items: [
            {
              type: :bill,
              name: "Water bill",
              due_at: Time.zone.parse("2026-11-15 09:00"),
              household_id: record.id
            }
          ]
        )
      end

      get calendar_path, params: { month: "2026-11" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Water bill", "Bill", "Apartment 303")
    end
  end
end
