# app/controllers/expenses_controller.rb
class ExpensesController < ApplicationController
  before_action :require_login
  before_action :set_household
  before_action :check_membership
  before_action :set_expense, only: [:edit, :update, :destroy]
  before_action :require_creator, only: [:edit, :update, :destroy]

  def index
    @expenses = @household.expenses
                          .includes(:created_by, :expense_participants)
                          .order(expense_date: :desc, created_at: :desc)
  end

  def new
    @expense = @household.expenses.build
  end

  def create
    @expense = @household.expenses.build(expense_params)
    @expense.created_by = current_user

    success = false
    Expense.transaction do
      success = @expense.save && apply_split
      raise ActiveRecord::Rollback unless success
    end

    if success
      redirect_to household_path(@household), notice: "Expense was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @expense = @household.expenses
                        .includes(:created_by, expense_participants: :user)
                        .find(params[:id])
  end

  def edit
  end

  def update
    @expense.assign_attributes(expense_params)

    success = false
    Expense.transaction do
      success = @expense.valid? &&
                (!@expense.amount_changed? || @expense.rescale_shares) &&
                @expense.save
      raise ActiveRecord::Rollback unless success
    end

    if success
      redirect_to household_expense_path(@household, @expense), notice: "Expense was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to household_path(@household), notice: "Expense was deleted."
  end

  def mark_paid
    @expense = @household.expenses.find(params[:id])
    @participant = @expense.expense_participants.find(params[:participant_id])

    if @participant.user == current_user
      @participant.mark_as_paid!
      redirect_back(fallback_location: household_path(@household),
                    notice: "Payment marked as complete.")
    else
      redirect_back(fallback_location: household_path(@household),
                    alert: "You can only mark your own payments.")
    end
  end

  helper_method :selected_member_ids, :split_type, :custom_split_value

  private

  def set_expense
    @expense = @household.expenses.find(params[:id])
  end

  def require_creator
    unless @expense.created_by == current_user
      redirect_to household_expense_path(@household, @expense),
                  alert: "Only the person who created this expense can change it."
    end
  end

  def set_household
    @household = Household.find(params[:household_id])
  end

  def check_membership
    unless @household.users.include?(current_user)
      redirect_to root_path, alert: "You are not a member of this household"
    end
  end

  def expense_params
    params.require(:expense).permit(:title, :description, :amount, :expense_date, :due_date)
  end

  def selected_member_ids
    @selected_member_ids ||=
      if params.key?(:selected_members)
        Array(params[:selected_members]).reject(&:blank?).map(&:to_s)
      else
        @household.users.pluck(:id).map(&:to_s)   # first load: everyone checked
      end
  end

  def split_type
    params[:split_type] == "custom" ? "custom" : "equal"
  end

  def custom_split_value(user_id)
    params.dig(:custom_splits, user_id.to_s).presence || 0
  end

  def apply_split
    if split_type == "custom"
      splits = params[:custom_splits]&.to_unsafe_h || {}
      @expense.split_custom(splits, selected_member_ids)
    else
      @expense.split_equally(selected_member_ids)
    end
  end
end
