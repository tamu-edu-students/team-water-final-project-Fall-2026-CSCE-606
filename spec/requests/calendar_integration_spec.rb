require "rails_helper"

RSpec.describe "Calendar integration contracts", type: :request do
  let!(:admin) { User.create!(name: "Admin", email: "calendar-admin@example.com", password: "password123") }
  let!(:member) { User.create!(name: "Member", email: "calendar-member@example.com", password: "password123") }
  let!(:household) { Household.create!(name: "Calendar house", creator: admin) }
  let(:payload) do
    { name: "Meeting", start_timestamp: "2026-11-03T09:00:00Z", end_timestamp: "2026-11-03T10:00:00Z",
      recurring: "DAILY", recurrence_until: "2026-11-06", attendee_ids: [ member.id ] }
  end
  let(:event) do
    household.events.create!(creator: member, **payload.except(:attendee_ids)).tap do |record|
      record.event_attendees.create!(user: member)
    end
  end
  let(:range) { { from: "2026-11-03T00:00:00Z", to: "2026-11-06T23:59:59Z" } }

  before do
    [ admin, member ].each { |user| household.household_memberships.create!(user: user) }
    post login_path, params: { email: member.email, password: "password123" }
  end

  { name: "", start_timestamp: "bad-time", end_timestamp: "2026-11-03T08:00:00Z",
    all_day: "yes", recurrence_until: "bad-date", recurring: "YEARLY",
    attendee_ids: [ "bad-id" ] }.each do |field, value|
    it "rejects invalid #{field} without persisting an event" do
      expect do
        post household_events_path(household), params: payload.merge(field => value), as: :json
      end.not_to change(Event, :count)
      expect(response).to have_http_status(:bad_request)
    end
  end

  it "expands only the requested attendee's events" do
    event
    get household_events_path(household), params: range.merge(user_id: member.id)
    expect(response.parsed_body.fetch("events").size).to eq(4)
    get household_events_path(household), params: range.merge(user_id: admin.id)
    expect(response.parsed_body.fetch("events")).to be_empty
    [ "bad-id", -1 ].each do |id|
      get household_events_path(household), params: range.merge(user_id: id)
      expect(response).to have_http_status(:bad_request)
    end
  end

  it "rejects missing, malformed and reversed ranges in both calendar APIs" do
    [ { from: "", to: range[:to] }, { from: "bad-time", to: range[:to] },
      { from: range[:to], to: range[:from] } ].each do |parameters|
      [ household_events_path(household), "/households/#{household.id}/calendar" ].each do |path|
        get path, params: parameters
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  it "changes a series' attendees, cancels one occurrence and deletes the series" do
    patch event_path(event), params: { name: "Series updated", attendee_ids: [ admin.id ], scope: "all" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(event.reload.attendee_ids).to eq([ admin.id ])

    delete event_path(event), params: { scope: "this", occurrence_start: "2026-11-04T09:00:00Z" }
    expect(response).to have_http_status(:no_content)
    get household_events_path(household), params: range
    expect(response.parsed_body.fetch("events").size).to eq(3)

    delete event_path(event), params: { scope: "all" }
    expect(response).to have_http_status(:no_content)
    expect(Event.exists?(event.id)).to be(false)
  end

  it "preserves a series when updates or occurrence requests are invalid" do
    [ { name: "", scope: "all" }, { attendee_ids: [ -1 ], scope: "all" },
      { start_timestamp: "bad-time", scope: "all" }, { scope: "invalid" },
      { scope: "this" }, { scope: "this", occurrence_start: "2026-12-01T09:00:00Z" },
      { scope: "this", occurrence_start: "2026-11-04T09:00:00Z", recurring: "WEEKLY" },
      { scope: "this", occurrence_start: "2026-11-04T09:00:00Z", end_timestamp: "2026-11-04T08:00:00Z" } ].each do |parameters|
      patch event_path(event), params: parameters, as: :json
      expect(response).to have_http_status(:bad_request)
    end
    [ { scope: "invalid" }, { scope: "this", occurrence_start: "bad-time" },
      { scope: "this", occurrence_start: "2026-12-01T09:00:00Z" } ].each do |parameters|
      delete event_path(event), params: parameters
      expect(response).to have_http_status(:bad_request)
    end
    expect(event.reload.name).to eq("Meeting")
    expect(event.event_exceptions).to be_empty
  end

  it "restricts event management to its creator or household admin" do
    event
    other = User.create!(name: "Other", email: "calendar-other@example.com", password: "password123")
    household.household_memberships.create!(user: other)
    post login_path, params: { email: other.email, password: "password123" }
    patch event_path(event), params: { name: "Unauthorized" }, as: :json
    expect(response).to have_http_status(:forbidden)
    delete event_path(event)
    expect(response).to have_http_status(:forbidden)
    post login_path, params: { email: admin.email, password: "password123" }
    patch event_path(event), params: { name: "Admin update" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(event.reload.name).to eq("Admin update")
  end

  it "rejects mutations by non-members and hides nonexistent records" do
    event
    household.household_memberships.find_by!(user: member).destroy!
    patch event_path(event), params: { name: "Former member" }, as: :json
    expect(response).to have_http_status(:forbidden)
    patch "/events/0", params: { name: "Missing" }, as: :json
    expect(response).to have_http_status(:not_found)
    get "/households/0/calendar", params: range
    expect(response).to have_http_status(:not_found)
  end
end
