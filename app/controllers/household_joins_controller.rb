
class HouseholdJoinsController < ApplicationController
  before_action :require_login
  before_action :load_selected_household

  # Opened from a shared invite link (?code=...): previews the household and prefills the code.
  def new
    @invite_code = params[:code].to_s.strip
    if @invite_code.present? && !@selected_household
      @household = Household.find_by(invite_code: @invite_code)
      if @household.nil?
        flash.now[:alert] = "This invite link is invalid or has expired."
      elsif @household.household_memberships.exists?(user: current_user)
        return redirect_to household_dashboard_path(@household), notice: "You are already a member of this household."
      else
        @selected_household = @household
      end
    end

    @query = params[:q].to_s.strip
    @search_results = []
    return if @query.blank? || @selected_household

    if @query.length > 100
      flash.now[:alert] = "Please search using 100 characters or fewer."
      return
    end

    pattern = "%#{Household.sanitize_sql_like(@query)}%"
    @search_results = Household.where("name ILIKE ?", pattern)
      .where.not(id: current_user.household_memberships.select(:household_id))
      .order(:name, :id).limit(20).select(:id, :name)
  end

  def create
    code = params[:invite_code].to_s.strip

    if code.blank?
      flash.now[:alert] = "Please enter an invitation code."
      return render :new, status: :unprocessable_content
    end

    # A code for a different household must never join it after a selection.
    household = if @selected_household
      Household.find_by(id: @selected_household.id, invite_code: code)
    else
      Household.find_by(invite_code: code)
    end

    unless household
      flash.now[:alert] = "Invalid invitation code."
      return render :new, status: :unprocessable_content
    end

    if household.household_memberships.exists?(user: current_user)
      return redirect_to household,
        alert: "You are already a member of this household."
    end

    begin
      household.household_memberships.create!(user: current_user)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      return redirect_to household,
        alert: "You are already a member of this household."
    end

    HouseholdNotificationDispatcher.member_joined(
      household: household,
      actor: current_user
    )

    redirect_to household,
      notice: "Successfully joined the household!"
  end

  private

  def load_selected_household
    return if params[:household_id].blank?

    @selected_household = Household.select(:id, :name).find(params[:household_id])
  end
end
