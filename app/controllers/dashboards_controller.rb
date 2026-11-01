class DashboardsController < ApplicationController
  before_action :require_login

  rescue_from ActiveRecord::RecordNotFound do
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def show
    # Scope the lookup before reading any household data, including member names.
    @household = current_user.households.find(params[:household_id])
    @members = @household.users.order(:name, :id).to_a

    @balance = BalanceCalculator.new(@household, current_user).calculate

    people    = BalanceCalculator.new(@household, current_user).by_person
    @owed_by  = people.select { |row| row[:net] > 0 }   # they owe me
    @you_owe  = people.select { |row| row[:net] < 0 }   # I owe them

    # Shares I still owe, for expenses someone else paid
    pending = ExpenseParticipant
      .joins(:expense)
      .includes(expense: :created_by)
      .where(user: current_user, payment_status: "pending")
      .where(expenses: { household_id: @household.id })
      .where.not(expenses: { created_by_id: current_user.id })

    @pending_shares  = pending.order("expenses.expense_date DESC").limit(5)
    @upcoming_bills  = pending.merge(Expense.due_by(5)).order("expenses.due_date ASC")
    @recent_expenses = @household.expenses
                                 .includes(:created_by)
                                 .order(expense_date: :desc, created_at: :desc)
                                 .limit(5)
  end
end
