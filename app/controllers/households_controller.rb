class HouseholdsController < ApplicationController
  before_action :require_login
  before_action :set_household, only: %i[show regenerate_invite_code leave]

  def index
    @households = current_user.households
  end

  def new
    @household = Household.new
  end

  def create
    @household = Household.new(household_params)
    @household.creator = current_user

    ActiveRecord::Base.transaction do
      @household.save!

      @household.household_memberships.create!(
        user: current_user,
        role: "admin"
      )
    end

    redirect_to @household, notice: "Household created successfully!"
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_content
  end

  def show
    @expenses = @household.expenses
                          .includes(:created_by, expense_participants: :user)
                          .order(expense_date: :desc)
                          .limit(10)

    # Calculate user's balance for this household
    # This supports the MVP requirement for balance tracking [1]
    @balance = BalanceCalculator.new(@household, current_user).calculate
  end

  def regenerate_invite_code
   unless @household.admin?(current_user)
     return redirect_to @household,
                        alert: "Only an admin can regenerate invitation codes."
   end

   @household.regenerate_invite_code

   redirect_to @household,
               notice: "Old invitation code revoked. A new code has been generated."
  end

  def leave
  result = nil

  @household.with_lock do
    membership = @household.household_memberships.find_by!(
      user: current_user
    )

    remaining = @household.household_memberships
                          .where.not(id: membership.id)

    if remaining.none?
      result = :last_member

    elsif membership.role == "admin" && !remaining.exists?(role: "admin")
      # The last admin must choose a successor before leaving.
      successor = remaining.find_by(
        user_id: params[:successor_user_id]
      )

      if successor.nil?
        result = :invalid_successor
      else
        successor.update!(role: "admin")
        membership.destroy!
        result = :left
      end

    else
      # Ordinary members, or admins when another admin remains.
      membership.destroy!
      result = :left
    end
  end

  case result
  when :last_member
    redirect_to @household,
                alert: "You cannot leave as the last household member."

  when :invalid_successor
    redirect_to @household,
                alert: "Please select a valid roommate as the next admin."

  when :left
    redirect_to households_path,
                notice: "You have successfully left the household."
  end
end

  private

  def household_params
    params.require(:household).permit(:name)
  end

  def set_household
    @household = current_user.households.find(params[:id])
  end
end
