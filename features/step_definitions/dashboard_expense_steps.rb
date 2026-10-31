module DashboardExpenseSteps
  def expense_dashboard_card
    expect(last_response.status).to eq(200)
    Nokogiri::HTML(last_response.body).at_css('[aria-labelledby="bills-heading"]')
  end

  def dashboard_expense_user(name)
    User.find_by!(email: "#{name.downcase}@dashboard.example.com")
  end

  def edit_dashboard_internet(amount)
    step 'I am logged in as "alice@dashboard.example.com"'
    expense = @expense_dashboard_household.expenses.find_by!(title: "Internet")
    get household_expense_path(@expense_dashboard_household, expense)
    edit_path = edit_household_expense_path(@expense_dashboard_household, expense)
    expect(Nokogiri::HTML(last_response.body).css("a").map { |link| link["href"] }).to include(edit_path)
    get edit_path
    expect(last_response.status).to eq(200)
    patch household_expense_path(@expense_dashboard_household, expense), expense: { amount: amount }
    expense
  end
end
World(DashboardExpenseSteps)

Given("an expense dashboard household with two roommates") do
  alice, bob = %w[Alice Bob].map do |name|
    User.create!(name: name, email: "#{name.downcase}@dashboard.example.com", password: "password123")
  end
  @expense_dashboard_household = Household.create!(name: "Expense House", creator: alice)
  [ alice, bob ].each { |user| @expense_dashboard_household.household_memberships.create!(user: user) }
  step 'I am logged in as "bob@dashboard.example.com"'
end

When("my roommate adds an Internet expense for 60 dollars through the app") do
  step 'I am logged in as "alice@dashboard.example.com"'
  post household_expenses_path(@expense_dashboard_household),
       expense: { title: "Internet", amount: "60.00", expense_date: Date.current, due_date: Date.current + 1 },
       split_type: "equal"
  expect(last_response).to be_redirect
  step 'I am logged in as "bob@dashboard.example.com"'
end

Given("these dashboard expense shares exist:") do |table|
  table.hashes.each do |row|
    expense = @expense_dashboard_household.expenses.create!(
      title: row["title"], amount: row["amount"], expense_date: Date.current - 30,
      due_date: row["due_days"].present? ? Date.current + row["due_days"].to_i : nil,
      created_by: dashboard_expense_user(row["owner"])
    )
    expense.expense_participants.create!(user: dashboard_expense_user(row["debtor"]),
                                         amount_owed: row["amount"], payment_status: row["status"])
  end
end

When("I submit the dashboard payment form for {string}") do |title|
  expense = @expense_dashboard_household.expenses.find_by!(title: title)
  action = mark_paid_household_expense_path(@expense_dashboard_household, expense)
  form = expense_dashboard_card.at_css("form[action='#{action}']")
  expect(form).not_to be_nil
  fields = form.css("input[name]").to_h { |input| [ input["name"], input["value"] ] }
  post form["action"], fields, "HTTP_REFERER" => last_request.url
  expect(last_response).to be_redirect
  expect(URI.parse(last_response.location).path).to eq(household_dashboard_path(@expense_dashboard_household))
  follow_redirect!
end

When("I try to pay my roommate's Internet share from the dashboard") do
  get household_dashboard_path(@expense_dashboard_household)
  expense = @expense_dashboard_household.expenses.find_by!(title: "Internet")
  other_share = expense.expense_participants.find_by!(user: dashboard_expense_user("Alice"))
  patch mark_paid_household_expense_path(@expense_dashboard_household, expense),
        { participant_id: other_share.id },
        "HTTP_REFERER" => last_request.url
  expect(last_response).to be_redirect
  follow_redirect!
end

Given("I also belong to a household with a private bill") do
  other = Household.create!(name: "Other Expense House", creator: dashboard_expense_user("Alice"))
  %w[Alice Bob].each { |name| other.household_memberships.create!(user: dashboard_expense_user(name)) }
  expense = other.expenses.create!(title: "Private bill", amount: "999.99", expense_date: Date.current,
                                   due_date: Date.current, created_by: dashboard_expense_user("Alice"))
  expense.expense_participants.create!(user: dashboard_expense_user("Bob"), amount_owed: "999.99", payment_status: "pending")
end

Then("the expense dashboard should show {string}") do |text|
  expect(expense_dashboard_card.text.squish).to include(text)
end

Then("the expense dashboard should not show {string}") do |text|
  expect(expense_dashboard_card.text).not_to include(text)
end

Then("the expense dashboard status should be {string}") do |status|
  expect(expense_dashboard_card.at_css(".dashboard-status").text.squish).to eq(status)
end

Then("the dashboard due-soon titles should be {string}") do |titles|
  expect(expense_dashboard_card.css(".dashboard-bills-due a").map(&:text)).to eq(titles.split(", "))
end

Then("only my share of {string} should be paid") do |title|
  expense = @expense_dashboard_household.expenses.find_by!(title: title)
  expect(expense.expense_participants.find_by!(user: dashboard_expense_user("Bob")).payment_status).to eq("paid")
  expect(expense.expense_participants.find_by!(user: dashboard_expense_user("Alice")).payment_status).to eq("pending")
end

Then("neither share of {string} should be paid") do |title|
  expense = @expense_dashboard_household.expenses.find_by!(title: title)
  expect(expense.expense_participants.pluck(:payment_status)).to eq([ "pending", "pending" ])
end

Then("the expense dashboard should have no payment forms") do
  expect(expense_dashboard_card.css("form")).to be_empty
end

Then("the expense dashboard should offer working expense links") do
  links = expense_dashboard_card.css("a").map { |link| link["href"] }
  expect(links).to include(new_household_expense_path(@expense_dashboard_household),
                          household_expenses_path(@expense_dashboard_household))
  links.each do |path|
    get path
    expect(last_response.status).to eq(200)
  end
end

When("my roommate changes Internet to 90 dollars through its edit page") do
  expense = edit_dashboard_internet("90.00")
  expect(last_response).to be_redirect
  expect(expense.reload.amount).to eq(BigDecimal("90.00"))
  step 'I am logged in as "bob@dashboard.example.com"'
end

When("my roommate tries an invalid Internet amount through its edit page") do
  expense = edit_dashboard_internet("-20.00")
  expect(last_response.status).to eq(422)
  expect(last_response.body).to include("must be greater than 0")
  expect(expense.reload.amount).to eq(BigDecimal("60.00"))
  step 'I am logged in as "bob@dashboard.example.com"'
end

When("my roommate tries to change Internet after my payment") do
  expense = edit_dashboard_internet("90.00")
  expect(last_response.status).to eq(422)
  expect(Nokogiri::HTML(last_response.body).text).to include("Amount can't be changed after a payment")
  expect(expense.reload.amount).to eq(BigDecimal("60.00"))
  step 'I am logged in as "bob@dashboard.example.com"'
end

When("my roommate deletes Internet through the app") do
  step 'I am logged in as "alice@dashboard.example.com"'
  expense = @expense_dashboard_household.expenses.find_by!(title: "Internet")
  delete household_expense_path(@expense_dashboard_household, expense)
  expect(last_response).to be_redirect
  expect(Expense.exists?(expense.id)).to be(false)
  step 'I am logged in as "bob@dashboard.example.com"'
end
