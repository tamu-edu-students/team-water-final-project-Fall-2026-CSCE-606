module InventorySteps
  def inventory_item(name)
    @household.inventory_items.find_by!(name: name)
  end

  def item_names
    Nokogiri::HTML(last_response.body).css(".inventory-item-name").map(&:text)
  end
end
World(InventorySteps)

When("I open the inventory for {string}") do |name|
  household = Household.find_by!(name: name)
  get "/households/#{household.id}/inventory"
end

When("I choose the {string} room") do |room|
  get "/households/#{@household.id}/inventory", room: room
end

When("I add {string} with a count of {int} to the {string} room") do |name, count, room|
  get "/households/#{@household.id}/inventory", room: room
  post "/households/#{@household.id}/inventory",
       inventory_item: { room: room, name: name, quantity: count }
  follow_redirect! if last_response.redirect?
end

When("I add {string} with a count of {int} and an alert at {int} to the {string} room") do |name, count, threshold, room|
  get "/households/#{@household.id}/inventory", room: room
  post "/households/#{@household.id}/inventory",
       inventory_item: { room: room, name: name, quantity: count, low_stock_threshold: threshold }
  follow_redirect! if last_response.redirect?
end

When("I add {string} owned by {string} to the {string} room") do |name, owner, room|
  get "/households/#{@household.id}/inventory", room: room
  post "/households/#{@household.id}/inventory",
       inventory_item: { room: room, name: name, owner: owner, quantity: 1 }
  follow_redirect! if last_response.redirect?
end

Then("{string} should show the owner {string}") do |name, owner|
  row = Nokogiri::HTML(last_response.body).css(".inventory-item").find { |item| item.at_css(".inventory-item-name").text == name }
  expect(row.at_css(".inventory-item-owner").text).to eq("Owner: #{owner}")
end

When("I edit {string} to be named {string} with a count of {int}") do |name, new_name, count|
  get "/households/#{@household.id}/inventory", room: "kitchen"
  patch "/households/#{@household.id}/inventory/#{inventory_item(name).id}",
        inventory_item: { name: new_name, quantity: count }
  follow_redirect! if last_response.redirect?
end

When("I delete {string}") do |name|
  get "/households/#{@household.id}/inventory", room: "kitchen"
  delete "/households/#{@household.id}/inventory/#{inventory_item(name).id}"
  follow_redirect! if last_response.redirect?
end

When("I lower the count of {string} by one") do |name|
  get "/households/#{@household.id}/inventory", room: "kitchen"
  patch "/households/#{@household.id}/inventory/#{inventory_item(name).id}/adjust", delta: -1
  follow_redirect! if last_response.redirect?
end

Then("the room should list {string}") do |names|
  expect(item_names).to eq(names.split(", "))
end

Then("the room should not list {string}") do |name|
  expect(item_names).not_to include(name)
end

Then("{string} should have a count of {int}") do |name, count|
  expect(inventory_item(name).quantity).to eq(count)
end

Then("the inventory card should show {string}") do |text|
  card = Nokogiri::HTML(last_response.body).at_css(".dashboard-inventory-card")
  expect(card.text).to include(text)
end

When("I open the inventory history") do
  get "/households/#{@household.id}/inventory/history"
end

Then("the history should list {string}") do |row|
  rows = Nokogiri::HTML(last_response.body).css(".inventory-history-table tbody tr").map do |tr|
    tr.css("td").drop(1).map { |td| td.text.strip }.join(" | ")
  end
  expect(rows).to include(row)
end
