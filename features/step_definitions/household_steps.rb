Given("I am logged in as {string}") do |email|
  user = User.find_or_create_by!(email: email) do |u|
    u.name = email.split("@").first.capitalize
    u.password = "password123"
  end

  post "/login", email: user.email, password: "password123"

  raise "Login failed" unless last_response.redirect?

  @current_user_email = user.email
end

Given("a household named {string} exists") do |name|
  creator = User.create!(
    name: "Alice",
    email: "alice@example.com",
    password: "password123"
  )

  @household = Household.create!(
    name: name,
    creator: creator
  )

  @household.household_memberships.create!(user: creator)
end

When("I create a household named {string}") do |name|
  post "/households", household: { name: name }

  @household = Household.find_by(name: name)
  follow_redirect! if last_response.redirect?
end

When("I join {string} using its invitation code") do |name|
  household = Household.find_by!(name: name)

  post "/join-household", invite_code: household.invite_code
  follow_redirect! if last_response.redirect?

  @household = household
end

When("I try to join a household with the code {string}") do |code|
  post "/join-household", invite_code: code
end

Then("I should see the household {string}") do |name|
  unless last_response.body.include?(name)
    raise "Expected to see household '#{name}' on the page"
  end
end

Then("I should be a member of {string}") do |name|
  household = Household.find_by!(name: name)
  user = User.find_by!(email: @current_user_email)

  unless household.users.include?(user)
    raise "Expected #{user.email} to be a household member"
  end
end

Then("I should see {string}") do |message|
  unless last_response.body.include?(message)
    raise "Expected to see '#{message}' on the page"
  end
end


Given("I already belong to {string}") do |name|
  household = Household.find_by!(name: name)
  user = User.find_by!(email: @current_user_email)

  household.household_memberships.find_or_create_by!(user: user)
end

Given("I am not logged in") do
  @current_user_email = nil

  # Clear any authentication session for this scenario.
  delete "/logout"
end

When("I try to join {string} using its invitation code") do |name|
  household = Household.find_by!(name: name)

  @membership_count_before = household.household_memberships.count

  post "/join-household",
       invite_code: household.invite_code

  @membership_count_after = household.household_memberships.count
end

When("I try to view the household {string}") do |name|
  household = Household.find_by!(name: name)

  @access_denied = false

  begin
    get "/households/#{household.id}"
  rescue ActiveRecord::RecordNotFound
    @access_denied = true
  end
end

Then("I should be redirected to the login page") do
  unless last_response.redirect? &&
         URI.parse(last_response.headers["Location"]).path == "/login"
    raise "Expected a redirect to /login, got #{last_response.status}"
  end
end

Then("I should not have joined {string}") do |name|
  unless @membership_count_before == @membership_count_after
    raise "A membership was created without authentication"
  end
end

Then("I should have exactly one membership in {string}") do |name|
  household = Household.find_by!(name: name)
  user = User.find_by!(email: @current_user_email)

  count = household.household_memberships.where(user: user).count

  unless count == 1
    raise "Expected exactly one membership, found #{count}"
  end
end

Then("I should receive a not found response") do
  unless @access_denied || last_response.status == 404
    raise "Expected access to be denied with HTTP 404"
  end
end
