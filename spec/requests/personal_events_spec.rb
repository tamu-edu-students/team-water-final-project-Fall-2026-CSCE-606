require "rails_helper"

RSpec.describe "Personal calendar events", type: :request do
  let!(:owner) { User.create!(name: "Owner", email: "personal-owner@example.com", password: "password123") }
  let!(:invitee) { User.create!(name: "Invitee", email: "personal-invitee@example.com", password: "password123") }
  let!(:outsider) { User.create!(name: "Outsider", email: "personal-outsider@example.com", password: "password123") }
  let!(:household) { Household.create!(name: "Personal Events House", creator: owner) }

  before do
    household.household_memberships.create!(user: owner)
    household.household_memberships.create!(user: invitee)
    post login_path, params: { email: owner.email, password: "password123" }
  end

  def calendar_for(user)
    post login_path, params: { email: user.email, password: "password123" }
    get calendar_path, params: { month: "2026-11" }
  end

  it "creates a private date-only event visible only to its creator" do
    post personal_events_path, params: {
      personal_event: {
        title: "Doctor appointment",
        event_date: "2026-11-12",
        visibility: "private"
      }
    }

    personal_event = PersonalEvent.last
    expect(response).to redirect_to(personal_event_path(personal_event))
    expect(personal_event).to have_attributes(
      event_date: Date.new(2026, 11, 12),
      visibility: "private",
      household_id: nil
    )

    get calendar_path, params: { month: "2026-11" }
    expect(response.body).to include("Doctor appointment", "Personal")

    calendar_for(invitee)
    expect(response.body).not_to include("Doctor appointment")

    get personal_event_path(personal_event)
    expect(response).to have_http_status(:not_found)
  end

  it "shares an event with selected household members and keeps it off other calendars" do
    post personal_events_path, params: {
      personal_event: {
        title: "Roommate dinner",
        event_date: "2026-11-14",
        visibility: "shared",
        household_id: household.id,
        attendee_ids: [ invitee.id ]
      }
    }

    personal_event = PersonalEvent.last
    expect(response).to redirect_to(personal_event_path(personal_event))
    expect(personal_event.attendee_ids).to eq([ invitee.id ])

    calendar_for(invitee)
    expect(response.body).to include("Roommate dinner", "Personal Events House")
    get personal_event_path(personal_event)
    expect(response).to have_http_status(:ok)

    calendar_for(outsider)
    expect(response.body).not_to include("Roommate dinner")
    get personal_event_path(personal_event)
    expect(response).to have_http_status(:not_found)
  end

  it "rejects attendees outside the selected household" do
    expect do
      post personal_events_path, params: {
        personal_event: {
          title: "Invalid share",
          event_date: "2026-11-14",
          visibility: "shared",
          household_id: household.id,
          attendee_ids: [ outsider.id ]
        }
      }
    end.not_to change(PersonalEvent, :count)

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "allows only the creator to edit or delete a shared event" do
    personal_event = owner.personal_events.create!(
      title: "Shared event",
      event_date: Date.new(2026, 11, 14),
      visibility: "shared",
      household: household
    )
    personal_event.personal_event_attendees.create!(user: invitee)
    post login_path, params: { email: invitee.email, password: "password123" }

    get edit_personal_event_path(personal_event)
    expect(response).to redirect_to(personal_event_path(personal_event))
    delete personal_event_path(personal_event)
    expect(response).to redirect_to(personal_event_path(personal_event))
    expect(PersonalEvent.exists?(personal_event.id)).to be(true)
  end
end
