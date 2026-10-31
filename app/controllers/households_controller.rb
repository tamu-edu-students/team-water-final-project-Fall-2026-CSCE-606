class HouseholdsController < ApplicationController
  before_action :require_login
  before_action :set_household, only: [ :show ]

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
  end

  private

  def household_params
    params.require(:household).permit(:name)
  end

  def set_household
    @household = current_user.households.find(params[:id])
  end
end
