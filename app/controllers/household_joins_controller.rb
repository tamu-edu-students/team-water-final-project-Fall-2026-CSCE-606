
class HouseholdJoinsController < ApplicationController
  before_action :require_login

  # Opened from a shared invite link (?code=...): previews the household and prefills the code.
  def new
    @invite_code = params[:code].to_s.strip
    return if @invite_code.blank?

    @household = Household.find_by(invite_code: @invite_code)
    if @household.nil?
      flash.now[:alert] = "This invite link is invalid or has expired."
    elsif @household.household_memberships.exists?(user: current_user)
      redirect_to household_dashboard_path(@household), notice: "You are already a member of this household."
    end
  end

  def create
    code = params[:invite_code].to_s.strip

    if code.blank?
      flash.now[:alert] = "Please enter an invitation code."
      return render :new, status: :unprocessable_content
    end

    household = Household.find_by(invite_code: code)

    unless household
      flash.now[:alert] = "Invalid invitation code."
      return render :new, status: :unprocessable_content
    end

    if household.household_memberships.exists?(user: current_user)
      return redirect_to household_rules_path(household),
        alert: "You are already a member of this household."
    end

    begin
      household.household_memberships.create!(user: current_user)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      return redirect_to household_rules_path(household),
        alert: "You are already a member of this household."
    end

    HouseholdNotificationDispatcher.member_joined(
      household: household,
      actor: current_user
    )

    redirect_to household_rules_path(household),
      notice: "Successfully joined the household!"
  end
end
