# app/services/balance_calculator.rb
class BalanceCalculator
  def initialize(household, user)
    @household = household
    @user = user
  end

  def calculate
    {
      total_owed_to_me: calculate_owed_to_user,
      total_i_owe: calculate_user_owes,
      net_balance: calculate_net_balance
    }
  end

  private

  def calculate_owed_to_user
    # Amount others owe for expenses I created
    # Get all expenses I created
    expenses_i_paid = Expense.where(created_by_id: @user.id, household_id: @household.id)

    total_owed = 0
    expenses_i_paid.each do |expense|
      # Sum what others owe me for this expense (exclude my own portion)
      others_portions = expense.expense_participants
                              .where.not(user_id: @user.id)
                              .where(payment_status: "pending")
                              .sum(:amount_owed)
      total_owed += others_portions
    end

    total_owed
  end

  def calculate_user_owes
    # Amount I owe for expenses others created
    ExpenseParticipant.joins(:expense)
                      .where(user_id: @user.id, payment_status: "pending")
                      .where(expenses: { household_id: @household.id })
                      .where.not(expenses: { created_by_id: @user.id })
                      .sum(:amount_owed)
  end

  def calculate_net_balance
    calculate_owed_to_user - calculate_user_owes
  end
end
