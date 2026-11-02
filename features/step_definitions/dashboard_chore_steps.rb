module DashboardChoreSteps
  def chore_dashboard_card
    expect(last_response.status).to eq(200)
    Nokogiri::HTML(last_response.body).at_css(".dashboard-chores-card")
  end

  def dashboard_chore(title)
    @expense_dashboard_household.chores.find_by!(title: title)
  end

  def create_dashboard_chore(title, due:, creator: dashboard_expense_user("Bob"), frequency: "NONE")
    @expense_dashboard_household.chores.create!(title: title, due_at: due, frequency: frequency,
                                               creator: creator).tap do |item|
      item.chore_assignments.create!(user: dashboard_expense_user("Bob"))
    end
  end
end
World(DashboardChoreSteps)

When("I add {string} due in {int} days through the chores page") do |title, days|
  get household_chores_path(@expense_dashboard_household)
  expect(last_response.status).to eq(200)
  expect(last_response.body).to include("Add a chore")
  post household_chores_path(@expense_dashboard_household), chore: {
    title: title, due_at: (Date.current + days).in_time_zone.change(hour: 18).iso8601,
    frequency: "NONE", assignee_ids: [ dashboard_expense_user("Bob").id ]
  }
  expect(last_response).to be_redirect
  expect(dashboard_chore(title)).to be_present
end

Given("these chore dates exist:") do |table|
  table.hashes.each do |row|
    due = (Date.current + row["due_days"].to_i).in_time_zone.change(hour: 18) if row["due_days"].present?
    create_dashboard_chore(row["title"], due: due)
  end
end

Given("a daily chore called {string} began {int} days ago") do |title, days|
  create_dashboard_chore(title, due: (Date.current - days).in_time_zone.change(hour: 18), frequency: "DAILY")
end

When("I move {string} outside the dashboard date range") do |title|
  item = dashboard_chore(title)
  get edit_household_chore_path(@expense_dashboard_household, item)
  expect(last_response.status).to eq(200)
  patch household_chore_path(@expense_dashboard_household, item), chore: {
    due_at: 9.days.from_now.iso8601, assignee_ids: [ dashboard_expense_user("Bob").id ]
  }
  expect(last_response).to be_redirect
end

When("I delete {string} through the chores page") do |title|
  item = dashboard_chore(title)
  delete household_chore_path(@expense_dashboard_household, item)
  expect(last_response).to be_redirect
  expect(Chore.exists?(item.id)).to be(false)
end

Given("that other household has a private chore") do
  other = Household.find_by!(name: "Other Expense House")
  other.chores.create!(creator: dashboard_expense_user("Alice"), title: "Private household chore",
                       due_at: Time.current).chore_assignments.create!(user: dashboard_expense_user("Bob"))
end

Given("my roommate created a chore called {string}") do |title|
  create_dashboard_chore(title, due: Time.current, creator: dashboard_expense_user("Alice"))
end

When("I try to change my roommate's chore from its edit route") do
  patch household_chore_path(@expense_dashboard_household, dashboard_chore("Roommate task")), chore: {
    title: "Tampered task", assignee_ids: [ dashboard_expense_user("Bob").id ]
  }
  expect(last_response).to be_redirect
  follow_redirect!
  expect(last_response.body).to include("Only the household admin or chore creator can edit this chore.")
end

Then("the chore should remain unchanged") do
  expect(dashboard_chore("Roommate task").title).to eq("Roommate task")
end

When("I try to add a chore with an outsider assignment") do
  outsider = User.create!(name: "Outsider", email: "outside-chore@example.com", password: "password123")
  post household_chores_path(@expense_dashboard_household), chore: {
    title: "Invalid assignment", assignee_ids: [ outsider.id ]
  }
  expect(last_response).to be_redirect
  follow_redirect!
  expect(last_response.body).to include("Choose one or more members of this household.")
end

Then("the chore dashboard should list {string}") do |title|
  expect(chore_dashboard_card.css(".dashboard-chore-schedule strong").map(&:text)).to include(title)
end

Then("the chore dashboard should show {string}") do |text|
  expect(chore_dashboard_card.text.squish).to include(text)
end

Then("the chore schedule titles should be {string}") do |titles|
  expect(chore_dashboard_card.css(".dashboard-chore-schedule strong").map(&:text)).to eq(titles.split(", "))
end

Then("the chore dashboard should show {int} scheduled dates out of {int}") do |shown, total|
  expect(chore_dashboard_card.css(".dashboard-chore-schedule li").size).to eq(shown)
  expect(chore_dashboard_card.text).to include("Showing the first #{shown} of #{total} scheduled dates.")
end

Then("the chore dashboard should have no scheduled dates") do
  expect(chore_dashboard_card.css(".dashboard-chore-schedule li")).to be_empty
  expect(chore_dashboard_card.text).to include("No chore dates scheduled")
end

Then("I should not see the private chore") do
  expect(last_response.body).not_to include("Private household chore")
end

Then("I can open chores and the calendar from the dashboard") do
  links = Nokogiri::HTML(last_response.body).css("a").map { |link| link["href"] }
  paths = [ household_chores_path(@expense_dashboard_household), calendar_path ]
  expect(links).to include(*paths)
  paths.each do |path|
    get path
    expect(last_response.status).to eq(200)
    expect(last_response.body).to include("Clean kitchen")
  end
end
