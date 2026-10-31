When("I open the dashboard for {string}") do |name|
  household = Household.find_by!(name: name)
  get "/households/#{household.id}/dashboard"
end

When("I open the dashboard home page") do
  get "/"
end

Then("only the unbuilt dashboard summaries should be marked unavailable") do
  expect(last_response.status).to eq(200)

  cards = Nokogiri::HTML(last_response.body).css(".dashboard-card")
  statuses = cards.to_h { |c| [ c.at_css("h2").text.strip, c.at_css(".dashboard-status").text.squish ] }

  expect(statuses.keys).to eq(
    [ "Chores", "Bills & balances", "Inventory alerts", "House rules & voting" ]
  )
  expect(statuses).to include(
    "Chores"               => "Not available yet",
    "Inventory alerts"     => "Not available yet",
    "House rules & voting" => "Not available yet"
  )

  unavailable = cards.reject { |c| c.at_css("h2").text.strip == "Bills & balances" }
  expect(unavailable.map(&:text).join).not_to include("$0.00")
  expect(last_response.body).not_to include("No upcoming tasks")
end

Then("the dashboard request should return not found") do
  expect(last_response.status).to eq(404)
end

Then("the dashboard response should not reveal {string}") do |name|
  household = Household.find_by!(name: name)
  expect(last_response.body).not_to include(name, household.invite_code)
end

Then("the dashboard should offer household details for {string}") do |name|
  household = Household.find_by!(name: name)
  links = Nokogiri::HTML(last_response.body).css("a").map { |link| link["href"] }
  expect(links).to include("/households/#{household.id}")
end

Then("the home page should offer the dashboard for {string}") do |name|
  household = Household.find_by!(name: name)
  links = Nokogiri::HTML(last_response.body).css("a").map { |link| link["href"] }
  expect(links).to include("/households/#{household.id}/dashboard")
end

Given("my membership in {string} has ended") do |name|
  household = Household.find_by!(name: name)
  user = User.find_by!(email: @current_user_email)
  household.household_memberships.find_by!(user: user).destroy!
end

When("I register for a dashboard account with matching passwords") do
  get "/signup"
  expect(last_response.status).to eq(200)
  post "/signup", user: { name: "New Roommate", email: "new@example.com",
                         password: "password123", password_confirmation: "password123" }
  expect(last_response).to be_redirect
  follow_redirect!
end

When("I register for a dashboard account without a name") do
  post "/signup", user: { name: "", email: "new@example.com",
                         password: "password123", password_confirmation: "password123" }
  expect(last_response.status).to eq(422)
end

When("I sign in to the dashboard with an incorrect password") do
  post "/login", email: "bob@example.com", password: "incorrect-password"
  expect(last_response.status).to eq(422)
end

When("I sign out from the dashboard home page") do
  get "/"
  expect(Nokogiri::HTML(last_response.body).at_css('form[action="/logout"]')).not_to be_nil
  delete "/logout"
end
