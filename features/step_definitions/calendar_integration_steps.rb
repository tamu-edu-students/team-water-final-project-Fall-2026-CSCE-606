module CalendarIntegrationSteps
  def calendar_event_payload
    { name: "House meeting", start_timestamp: "2026-11-03T09:00:00Z",
      end_timestamp: "2026-11-03T10:00:00Z", recurring: "NONE",
      attendee_ids: [ dashboard_expense_user("Bob").id ] }
  end

  def event_range
    { from: "2026-11-03T00:00:00Z", to: "2026-11-06T23:59:59Z" }
  end

  def submit_calendar_event(payload)
    post household_events_path(@expense_dashboard_household), payload.to_json, "CONTENT_TYPE" => "application/json"
  end

  def update_calendar_event(payload, query = {})
    patch event_path(@calendar_event, **query), payload.to_json, "CONTENT_TYPE" => "application/json"
  end

  def calendar_response
    JSON.parse(last_response.body)
  end
end
World(CalendarIntegrationSteps)

When("I create a {string} calendar event through the API") do |recurrence|
  attributes = calendar_event_payload.merge(recurring: recurrence)
  attributes[:recurrence_until] = "2026-11-06" unless recurrence == "NONE"
  submit_calendar_event(attributes)
  expect(last_response.status).to eq(201)
  @calendar_event = Event.find(calendar_response.fetch("event_id"))
end

Then("the event appears in my calendar and household feed") do
  get household_events_path(@expense_dashboard_household), event_range
  expect(calendar_response.fetch("events").map { |item| item["name"] }).to eq([ "House meeting" ])
  get "/households/#{@expense_dashboard_household.id}/calendar", event_range
  expect(calendar_response.fetch("items").map { |item| item["name"] }).to eq([ "House meeting" ])
  get calendar_path, month: "2026-11"
  expect(last_response.status).to eq(200)
  expect(last_response.body).to include("House meeting")
end

When("I update the single event and its attendees") do
  update_calendar_event(name: "Updated meeting", attendee_ids: [ dashboard_expense_user("Bob").id,
                                                               dashboard_expense_user("Alice").id ])
  expect(last_response.status).to eq(200)
end

Then("the updated event appears once in the calendar") do
  get household_events_path(@expense_dashboard_household), event_range
  expect(calendar_response.fetch("events").map { |item| item["name"] }).to eq([ "Updated meeting" ])
end

When("I delete the whole event") do
  delete event_path(@calendar_event), scope: "all"
  expect(last_response.status).to eq(204)
end

Then("the calendar event is removed") do
  get household_events_path(@expense_dashboard_household), event_range
  expect(calendar_response.fetch("events")).to be_empty
  expect(Event.exists?(@calendar_event.id)).to be(false)
end

When("I move one occurrence beyond the series end") do
  update_calendar_event({ name: "Moved meeting", start_timestamp: "2026-11-10T12:00:00Z",
                          end_timestamp: "2026-11-10T13:00:00Z" },
                        scope: "this", occurrence_start: "2026-11-04T09:00:00Z")
  expect(last_response.status).to eq(200)
  expect(calendar_response.fetch("original_start")).to eq("2026-11-04T09:00:00Z")
end

Then("the moved event appears on its destination date") do
  get household_events_path(@expense_dashboard_household), from: "2026-11-10T00:00:00Z", to: "2026-11-10T23:59:59Z"
  expect(calendar_response.fetch("events").map { |item| item["name"] }).to eq([ "Moved meeting" ])
end

When("I cancel that occurrence") do
  delete event_path(@calendar_event), scope: "this", occurrence_start: "2026-11-04T09:00:00Z"
  expect(last_response.status).to eq(204)
end

Then("the destination date has no event") do
  get household_events_path(@expense_dashboard_household), from: "2026-11-10T00:00:00Z", to: "2026-11-10T23:59:59Z"
  expect(calendar_response.fetch("events")).to be_empty
end

When("I update the entire event series") do
  update_calendar_event({ name: "Updated series", attendee_ids: [ dashboard_expense_user("Bob").id ] }, scope: "all")
  expect(last_response.status).to eq(200)
  expect(@calendar_event.reload.name).to eq("Updated series")
end

Then("another household member cannot edit or delete my event") do
  member = User.create!(name: "Carol", email: "calendar-carol@example.com", password: "password123")
  @expense_dashboard_household.household_memberships.create!(user: member)
  step 'I am logged in as "calendar-carol@example.com"'
  update_calendar_event(name: "Unauthorized")
  expect(last_response.status).to eq(403)
  delete event_path(@calendar_event)
  expect(last_response.status).to eq(403)
  expect(@calendar_event.reload.name).to eq("House meeting")
end

Then("a household admin can edit my event") do
  step 'I am logged in as "alice@dashboard.example.com"'
  update_calendar_event(name: "Admin update")
  expect(last_response.status).to eq(200)
  expect(@calendar_event.reload.name).to eq("Admin update")
end

Then("an outsider cannot read or change the household calendar") do
  step 'I am logged in as "calendar-outsider@example.com"'
  get "/households/#{@expense_dashboard_household.id}/calendar", event_range
  expect(last_response.status).to eq(403)
  get household_events_path(@expense_dashboard_household), event_range
  expect(last_response.status).to eq(403)
  update_calendar_event(name: "Outsider update")
  expect(last_response.status).to eq(403)
  get "/households/0/calendar", event_range
  expect(last_response.status).to eq(404)
  patch "/events/0", name: "Missing"
  expect(last_response.status).to eq(404)
end

Then("a signed-out user cannot read the calendar API") do
  delete logout_path
  get "/households/#{@expense_dashboard_household.id}/calendar", event_range
  expect(last_response.status).to eq(401)
end

When("I submit an event with invalid {string} set to {string}") do |field, value|
  @events_before_invalid_request = Event.count
  submit_calendar_event(calendar_event_payload.merge(field.to_sym => JSON.parse(value)))
end

Then("the event API should reject the request without saving") do
  expect(last_response.status).to eq(400)
  expect(calendar_response.fetch("error")).to be_present
  expect(Event.count).to eq(@events_before_invalid_request)
end

Then("invalid calendar ranges and member filters are rejected") do
  [ { from: "", to: "2026-11-04T00:00:00Z" },
    { from: "bad-date", to: "2026-11-04T00:00:00Z" },
    { from: "2026-11-04T00:00:00Z", to: "2026-11-03T00:00:00Z" } ].each do |range|
    [ household_events_path(@expense_dashboard_household), "/households/#{@expense_dashboard_household.id}/calendar" ].each do |path|
      get path, range
      expect(last_response.status).to eq(400)
    end
  end
  [ "bad-id", -1 ].each do |user_id|
    get household_events_path(@expense_dashboard_household), event_range.merge(user_id: user_id)
    expect(last_response.status).to eq(400)
  end
end

Then("the event list respects its attendee filter") do
  get household_events_path(@expense_dashboard_household), event_range.merge(user_id: dashboard_expense_user("Alice").id)
  expect(calendar_response.fetch("events")).to be_empty
  get household_events_path(@expense_dashboard_household), event_range.merge(user_id: dashboard_expense_user("Bob").id)
  expect(calendar_response.fetch("events").size).to eq(4)
end

Then("invalid event updates and occurrence requests are rejected") do
  [ [ { name: "No" }, { scope: "invalid" } ],
    [ { attendee_ids: [ -1 ] }, { scope: "all" } ],
    [ { name: "" }, { scope: "all" } ],
    [ { start_timestamp: "bad" }, { scope: "all" } ],
    [ { name: "No" }, { scope: "this" } ],
    [ { name: "No" }, { scope: "this", occurrence_start: "2026-12-01T09:00:00Z" } ],
    [ { recurring: "WEEKLY" }, { scope: "this", occurrence_start: "2026-11-04T09:00:00Z" } ],
    [ { end_timestamp: "2026-11-04T08:00:00Z" }, { scope: "this", occurrence_start: "2026-11-04T09:00:00Z" } ] ].each do |payload, query|
    update_calendar_event(payload, query)
    expect(last_response.status).to eq(400)
  end
  [ { scope: "invalid" }, { scope: "this", occurrence_start: "bad-time" },
    { scope: "this", occurrence_start: "2026-12-01T09:00:00Z" } ].each do |query|
    delete event_path(@calendar_event), query
    expect(last_response.status).to eq(400)
  end
end

Then("the original recurring event is unchanged") do
  expect(@calendar_event.reload.name).to eq("House meeting")
  expect(@calendar_event.event_exceptions).to be_empty
end

Then("invalid single-event updates are rejected") do
  [ { attendee_ids: [ -1 ] }, { name: "" } ].each do |payload|
    update_calendar_event(payload)
    expect(last_response.status).to eq(400)
  end
  expect(@calendar_event.reload.name).to eq("House meeting")
end
