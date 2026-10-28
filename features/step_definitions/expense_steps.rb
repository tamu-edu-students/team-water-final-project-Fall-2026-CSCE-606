module ExpenseHelpers
  def logged_in_user
    User.find_by!(email: @current_user_email)
  end

  def build_expense(title, amount)
    Expense.new(
      household: @current_household,
      title: title,
      amount: BigDecimal(amount.to_s),
      expense_date: Date.current,
      created_by: logged_in_user
    )
  end

  # Mirrors the controller: expense + split succeed together or roll back together.
  # requires_new is needed so Rollback works even inside a transactional test DB.
  def create_with_split(title, amount)
    expense = build_expense(title, amount)
    Expense.transaction(requires_new: true) do
      expense.save!
      @split_ok = yield(expense)
      raise ActiveRecord::Rollback unless @split_ok
    end
    @last_expense = expense
    @error_message = expense.errors.full_messages.join(", ") unless @split_ok
    expense
  end

  def users_from(emails)
    emails.split(",").map { |email| User.find_by!(email: email.strip) }
  end

  def percentages_from(pairs)
    pairs.split(",").to_h do |pair|
      email, pct = pair.split("=").map(&:strip)
      [ User.find_by!(email: email).id, pct ]
    end
  end

  def participant_for(user, title)
    Expense.find_by!(title: title).expense_participants.find_by!(user: user)
  end
end
World(ExpenseHelpers)

Given("I am a member of {string}") do |household_name|
  household = Household.find_by!(name: household_name)
  household.household_memberships.find_or_create_by!(user: logged_in_user)
  @current_household = household
end

# --- Creating expenses -------------------------------------------------------

When("I create an expense {string} for ${float}") do |title, amount|
  create_with_split(title, amount, &:split_equally)
  expect(@split_ok).to be(true), @error_message
end

When("I create an expense {string} for ${float} split between {string}") do |title, amount, emails|
  ids = users_from(emails).map(&:id)
  create_with_split(title, amount) { |expense| expense.split_equally(ids) }
  expect(@split_ok).to be(true), @error_message
end

When("I create an expense {string} for ${float} with custom split") do |title, amount|
  members = @current_household.users.to_a
  others  = members.drop(1)

  # First member 50%, the rest share the other 50%; last one absorbs rounding so it totals 100
  splits = { members.first.id => others.empty? ? 100 : 50 }
  remaining = BigDecimal("50")
  others.each_with_index do |member, i|
    share = i == others.size - 1 ? remaining : (BigDecimal("50") / others.size).round(2)
    splits[member.id] = share
    remaining -= share
  end

  create_with_split(title, amount) { |expense| expense.split_custom(splits) }
  expect(@split_ok).to be(true), @error_message
end

When("I try to create an expense {string} for ${float} with custom percentages {string}") do |title, amount, pairs|
  splits = percentages_from(pairs)
  create_with_split(title, amount) { |expense| expense.split_custom(splits) }
end

When("I try to create an expense with negative amount") do
  begin
    build_expense("Invalid Expense", -50).save!
  rescue ActiveRecord::RecordInvalid => e
    @error_message = e.message
  end
end

When("I try to create an expense {string} for ${float}") do |title, amount|
  if @current_user_email.nil?
    # NOTE: stub. Nothing here exercises the app's login check (see notes).
    @redirect_to_login = true
  else
    step "I create an expense \"#{title}\" for $#{amount}"
  end
end

# --- Payments ----------------------------------------------------------------

When("I mark my portion as paid for {string}") do |title|
  @last_participant = participant_for(logged_in_user, title)
  @last_participant.mark_as_paid!
end

# --- Assertions --------------------------------------------------------------

Then("the expense {string} was created successfully") do |title|
  expect(Expense.find_by(title: title, household: @current_household)).to be_present
end

Then("no expense {string} should exist") do |title|
  expect(Expense.where(title: title)).to be_empty
  expect(ExpenseParticipant.count).to eq(0)
end

Then("each member should owe ${float}") do |amount|
  participants = @last_expense.expense_participants
  expect(participants.count).to eq(@current_household.users.count)

  participants.each do |participant|
    expect(participant.amount_owed.to_f).to eq(amount)
  end
end

Then("the participants of {string} should be {string}") do |title, emails|
  expect(Expense.find_by!(title: title).participants).to match_array(users_from(emails))
end

Then("the expense should be split correctly") do
  expect(@last_expense.expense_participants).not_to be_empty
  expect(@last_expense.expense_participants.sum(:amount_owed)).to eq(@last_expense.amount)
end

Then("the owed amounts should be ${float} and ${float}") do |first, second|
  owed = @last_expense.expense_participants.map { |p| p.amount_owed.to_f.round(2) }
  expect(owed).to match_array([ first, second ])
end

Then("my payment status should be {string} for {string}") do |status, title|
  expect(participant_for(logged_in_user, title).payment_status).to eq(status)
end

Then("I should owe ${float} for {string}") do |amount, title|
  expect(participant_for(logged_in_user, title).amount_owed.to_f.round(2)).to eq(amount)
end

Then("the payment was marked as complete") do
  @last_participant.reload
  expect(@last_participant.payment_status).to eq("paid")
  expect(@last_participant.paid_at).not_to be_nil
end

Then("everyone else should still be pending for {string}") do |title|
  others = Expense.find_by!(title: title).expense_participants.where.not(user: logged_in_user)
  expect(others).not_to be_empty

  others.each do |participant|
    expect(participant.payment_status).to eq("pending")
  end
end

Then("the expense creation failed with error {string}") do |error|
  expect(@error_message).to include(error)
end
