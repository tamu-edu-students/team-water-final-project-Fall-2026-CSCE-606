Given("another roommate {string} belongs to {string}") do |email, household_name|
  household = Household.find_by!(name: household_name)
  user = User.find_or_create_by!(email: email) do |u|
    u.name = email.split("@").first.capitalize
    u.password = "password123"
  end
  household.household_memberships.find_or_create_by!(user: user)
end

When("I propose a rule {string} with category {string} and description {string}") do |title, category, description|
  post "/households/#{@household.id}/rules", rule: {
    title: title,
    category: category,
    description: description
  }
  follow_redirect! if last_response.redirect?
end

Then("the rule {string} was proposed successfully") do |title|
  expect(last_response.status).to eq(200)
  expect(last_response.body).to include("Rule proposal was successfully submitted.")
  expect(Rule.exists?(title: title)).to be true
end

Then("{string} should be listed under active proposals") do |title|
  expect(last_response.body).to include("Active Proposals &amp; Voting")
  expect(last_response.body).to include(title)
end

When("I try to propose a rule with empty title") do
  post "/households/#{@household.id}/rules", rule: {
    title: "",
    category: "General",
    description: "Missing title"
  }
end

Then("rule creation should fail with an error") do
  expect(last_response.status).to eq(422)
  expect(last_response.body).to include("Please correct the following errors")
end

Then("no rule should exist") do
  expect(Rule.count).to eq(0)
end

When("{string} votes {string} on {string}") do |email, decision, title|
  user = User.find_by!(email: email)
  rule = Rule.find_by!(title: title)

  # Log in as that roommate to cast vote
  post "/login", email: user.email, password: "password123"
  post "/households/#{@household.id}/rules/#{rule.id}/vote", decision: decision
  follow_redirect! if last_response.redirect?
end

Then("the rule {string} should be approved") do |title|
  rule = Rule.find_by!(title: title)
  expect(rule.status).to eq("approved")
end

Then("{string} should be displayed under approved house rules") do |title|
  expect(last_response.body).to include("Approved House Rules")
  expect(last_response.body).to include(title)
end

Then("the rule {string} should be rejected") do |title|
  rule = Rule.find_by!(title: title)
  expect(rule.status).to eq("rejected")
end

When("I try to vote {string} on {string} again") do |decision, title|
  rule = Rule.find_by!(title: title)
  post "/households/#{@household.id}/rules/#{rule.id}/vote", decision: decision
  follow_redirect! if last_response.redirect?
end

Given("an approved rule {string} exists in {string} with description {string}") do |title, household_name, description|
  household = Household.find_by!(name: household_name)
  creator = household.users.first
  rule = Rule.create!(
    household: household,
    created_by: creator,
    title: title,
    description: description,
    category: "General"
  )
  # Ensure all members vote approve so it's fully approved
  household.users.each do |u|
    rule.rule_votes.find_or_create_by!(user: u) { |v| v.decision = "approve" }
  end
  rule.evaluate_status!
  expect(rule.reload.status).to eq("approved")
end

When("I propose an amendment to {string} with description {string} and reason {string}") do |parent_title, description, reason|
  parent_rule = Rule.find_by!(title: parent_title)
  post "/households/#{@household.id}/rules/#{parent_rule.id}/amend", rule: {
    description: description,
    amendment_reason: reason
  }
  follow_redirect! if last_response.redirect?
end

Then("the amendment for {string} was proposed successfully") do |_parent_title|
  expect(last_response.status).to eq(200)
  expect(last_response.body).to include("Amendment proposal was successfully submitted.")
end

Then("the amendment should be listed under active proposals") do
  expect(last_response.body).to include("Active Proposals &amp; Voting")
  expect(last_response.body).to include("Amendment:")
end

When("{string} votes {string} on the amendment for {string}") do |email, decision, parent_title|
  user = User.find_by!(email: email)
  parent_rule = Rule.find_by!(title: parent_title)
  amendment = parent_rule.amendments.last

  post "/login", email: user.email, password: "password123"
  post "/households/#{@household.id}/rules/#{amendment.id}/vote", decision: decision
  follow_redirect! if last_response.redirect?
end

Then("the rule {string} should have updated description {string}") do |title, new_description|
  rule = Rule.find_by!(title: title)
  expect(rule.description).to eq(new_description)
end

Then("the revision history for {string} should show {int} versions") do |title, version_count|
  rule = Rule.find_by!(title: title)
  expect(rule.rule_revisions.count).to eq(version_count)
end

When("I try to view rules for {string}") do |household_name|
  household = Household.find_by!(name: household_name)
  get "/households/#{household.id}/rules"
  follow_redirect! if last_response.redirect?
end

Then("I should be redirected to the home page with an alert") do
  expect(last_response.body).to include("You are not a member of this household")
end
