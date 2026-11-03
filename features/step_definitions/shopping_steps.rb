module ShoppingSteps
  def shopping_item(name)
    @household.shopping_items.find_by!(name: name)
  end

  def shopping_dialog
    Nokogiri::HTML(last_response.body).at_css("dialog.shopping-dialog")
  end
end
World(ShoppingSteps)

When("I open the shopping list for {string}") do |name|
  household = Household.find_by!(name: name)
  get "/households/#{household.id}/inventory", cart: "open"
end

Given("{string} is on the shopping list") do |name|
  @household.shopping_items.create!(name: name, added_by: User.find_by!(email: @current_user_email))
end

When("I add {string} with quantity {int} and {string} priority to the shopping list") do |name, quantity, priority|
  get "/households/#{@household.id}/inventory", cart: "open"
  post "/households/#{@household.id}/shopping",
       shopping_item: { name: name, quantity: quantity, priority: priority, category: "Groceries" }
  follow_redirect! if last_response.redirect?
end

When("I add the suggested {string} to the shopping list") do |name|
  item = inventory_item(name)
  post "/households/#{@household.id}/shopping",
       shopping_item: { name: item.name, inventory_item_id: item.id, category: "Household" }
  follow_redirect! if last_response.redirect?
end

When("I mark {string} as bought") do |name|
  patch "/households/#{@household.id}/shopping/#{shopping_item(name).id}/purchase"
  follow_redirect! if last_response.redirect?
end

When("I remove {string} from the shopping list") do |name|
  get "/households/#{@household.id}/inventory", cart: "open"
  delete "/households/#{@household.id}/shopping/#{shopping_item(name).id}"
  follow_redirect! if last_response.redirect?
end

Then("the shopping list should show {string}") do |text|
  expect(shopping_dialog.text).to include(text)
end

Then("the shopping list should suggest {string}") do |name|
  suggestions = shopping_dialog.at_css("#running-low-heading").parent
  expect(suggestions.text).to include(name)
end
