class ExpensesController < ApplicationController
  before_action :set_household

  def create
    @expense = @household.expenses.build(expense_params)
    @expense.created_by = current_user

    if @expense.save
      handle_expense_split
      redirect_to household_path(@household),
                  notice: "Expense created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_household
    # Use the household_id from params, not current_user.household
    @household = Household.find(params[:household_id])

    # Optional: verify user is a member of this household
    unless @household.users.include?(current_user)
      redirect_to root_path, alert: "You are not a member of this household"
    end
  end

  def current_user
    # Since authentication isn't implemented, mock it for testing
    @current_user ||= User.first
  end

  def expense_params
    params.require(:expense).permit(:title, :amount, :expense_date)
  end

  def handle_expense_split
    if params[:split_type] == "equal"
      @expense.split_equally
    else
      @expense.split_custom(params[:custom_splits])
    end
  end
end
