Given("I sign in through the household search interface") do
  @search_user = User.create!(name: "Searcher", email: "search@example.com", password: "password123")
  visit "/login"
  fill_in "Email address", with: @search_user.email
  fill_in "Password", with: "password123"
  click_button "Log In"
end

When("I search for households named {string}") do |query|
  visit "/join-household"
  fill_in "Search by household name", with: query
  click_button "Search Households"
end

When("I select the household search result {string}") do |name|
  @search_household = Household.find_by!(name: name)
  within ".house-search-results" do
    click_link "Select"
  end
end

When("I submit the selected household's invitation code") do
  fill_in "Invitation Code", with: @search_household.invite_code
  click_button "Join Household"
end

When("I enter an incorrect code for the selected household") do
  fill_in "Invitation Code", with: "incorrect-code"
  click_button "Join Household"
end

Then("the household search page says {string}") do |message|
  expect(page).to have_content(message)
end

Then("my search account belongs to {string}") do |name|
  expect(@search_user.households.reload).to include(Household.find_by!(name: name))
end

Then("my search account has not joined any household") do
  expect(@search_user.households.reload).to be_empty
end
