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
      households = [ "Apartment 101", "Apartment 202" ].map do |name|
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
      household_chore = households.first.chores.create!(
        creator: user,
        title: "Clean the kitchen",
        due_at: Time.zone.parse("2026-11-12 16:00"),
        frequency: "WEEKLY"
      )
      household_chore.chore_assignments.create!(user: other_member)
      expense = households.first.expenses.create!(
        title: "November utilities",
        amount: "84.50",
        expense_date: Date.new(2026, 11, 1),
        due_date: Date.new(2026, 11, 12),
        created_by: user
      )

      post login_path, params: { email: user.email, password: "password123" }
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Dinner with me", "Whole household dinner")
      expect(response.body).to include("Open calendar", "dashboard-nav-icon")

      get calendar_path, params: { month: "2026-11" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My calendar", "November 2026", "Dinner with me")
      expect(response.body).to include("Whole household dinner", "Apartment 202", "Take out trash", "Chore")
      expect(response.body).not_to include("Other member only", "Clean the kitchen")
      household_selector = Nokogiri::HTML(response.body).at_css("#household_id")
      expect(household_selector.css("option").map(&:text)).to include(
        "All households",
        "Apartment 101",
        "Apartment 202"
      )
      calendar_controls = Nokogiri::HTML(response.body).at_css("[data-controller='calendar-filter']")
      expect(calendar_controls["data-action"]).to include(
        "change->calendar-filter#submit",
        "turbo:before-cache@document->calendar-filter#reset",
        "turbo:fetch-request-error@document->calendar-filter#reset"
      )
      filters = calendar_controls.at_css("form.dashboard-calendar-filters")
      expect(filters["data-calendar-filter-target"]).to eq("form")
      loading_overlay = Nokogiri::HTML(response.body).at_css(".dashboard-calendar-loading")
      expect(loading_overlay.attribute("hidden")).not_to be_nil
      expect(loading_overlay["role"]).to eq("status")
      expect(loading_overlay.text).to include("Updating calendar")
      expect(loading_overlay).to have_css(".dashboard-calendar-spinner")
      expect(filters.css('input[type="submit"], button[type="submit"]')).to be_empty
      expense_link = Nokogiri::HTML(response.body).at_css("a[href='#{household_expense_path(households.first, expense)}']")
      expect(expense_link.text).to eq("November utilities")
      chore_link = Nokogiri::HTML(response.body).at_css(
        "a[href='#{household_chores_path(households.first, anchor: "chore-#{chore.id}")}']"
      )
      expect(chore_link.text).to eq("Take out trash")
      expect(response.body).to include("Expense", "$84.50", "Apartment 101")
      calendar_document = Nokogiri::HTML(response.body)
      add_menu = calendar_document.at_css(".dashboard-calendar-add-menu")
      expect(add_menu.css("a").map { |link| link["href"] }).to include(
        household_chores_path(households.first, due_on: "2026-11-01", anchor: "create-chore-heading"),
        new_household_expense_path(households.first, calendar_date: "2026-11-01"),
        new_personal_event_path(date: "2026-11-01")
      )

      get calendar_path, params: {
        month: "2026-11",
        view: "household",
        household_id: households.first.id
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Household calendar", "Other member only", "Clean the kitchen")
      expect(response.body).not_to include("Whole household dinner")
      household_events = Nokogiri::HTML(response.body).css(".dashboard-calendar-item").map(&:text).join
      expect(household_events).not_to include("Apartment 202")

      get household_expense_path(households.first, expense)
      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML(response.body).at_css("h1").text).to eq("November utilities")

      get household_chores_path(households.first)
      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML(response.body).at_css("#chore-#{chore.id} strong").text).to eq("Take out trash")

      get household_chores_path(households.first), params: { due_on: "2026-11-13" }
      chore_due_field = Nokogiri::HTML(response.body).at_css("#chore_due_at")
      expect(chore_due_field["value"]).to start_with("2026-11-13T")

      get new_household_expense_path(households.first), params: { calendar_date: "2026-11-13" }
      expense_form = Nokogiri::HTML(response.body)
      expect(expense_form.at_css("#expense_expense_date")["value"]).to eq("2026-11-13")
      expect(expense_form.at_css("#expense_due_date")["value"]).to eq("2026-11-13")

      get new_personal_event_path, params: { date: "2026-11-13" }
      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML(response.body).at_css("#personal_event_event_date")["value"]).to eq("2026-11-13")
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
