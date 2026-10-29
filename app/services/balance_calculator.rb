# app/services/balance_calculator.rb
class BalanceCalculator
  # Combined balance across every household the user has expenses in.
  def self.for_all_households(user)
    new(nil, user).calculate
  end

  # { household_id => { total_owed_to_me:, total_i_owe:, net_balance: } }
  def self.by_household(user)
    new(nil, user).by_household
  end

  # household: a Household for a single-household balance, or nil for all of them.
  def initialize(household, user)
    @household = household
    @user = user
  end

  def calculate
    owed = total_owed_to_user
    owes = total_user_owes

    {
      total_owed_to_me: owed,
      total_i_owe: owes,
      net_balance: owed - owes
    }
  end

  def by_household
    owed = owed_scope.group("expenses.household_id").sum(:amount_owed)
    owes = owes_scope.group("expenses.household_id").sum(:amount_owed)

    (owed.keys | owes.keys).to_h do |household_id|
      o = owed.fetch(household_id, 0).to_d
      i = owes.fetch(household_id, 0).to_d
      [household_id, { total_owed_to_me: o, total_i_owe: i, net_balance: o - i }]
    end
  end

  private

  def total_owed_to_user
    owed_scope.sum(:amount_owed).to_d
  end

  def total_user_owes
    owes_scope.sum(:amount_owed).to_d
  end

  # Others' pending shares of expenses I created (my own share excluded)
  def owed_scope
    pending_shares
      .where(expenses: { created_by_id: @user.id })
      .where.not(user_id: @user.id)
  end

  # My pending shares of expenses others created
  def owes_scope
    pending_shares
      .where(user_id: @user.id)
      .where.not(expenses: { created_by_id: @user.id })
  end

  def pending_shares
    scope = ExpenseParticipant.joins(:expense).where(payment_status: "pending")
    scope = scope.where(expenses: { household_id: @household.id }) if @household
    scope
  end
end