class HouseholdMembershipsController < ApplicationController
  before_action :require_login
  before_action :set_household

  def destroy
    result = nil

    @household.with_lock do
      unless @household.admin?(current_user)
        result = :unauthorized
        next
      end

      membership = @household.household_memberships.find(params[:id])

      if membership.user_id == current_user.id
        result = :cannot_remove_self
      elsif membership.role == "admin"
        result = :cannot_remove_admin
      else
        # Remove membership and revoke the old invitation code.
        membership.destroy!
        @household.regenerate_invite_code
        result = :removed
      end
    end

    case result
    when :removed
      redirect_to @household,
                  notice: "Roommate removed successfully. Invitation code regenerated."
    when :unauthorized
      redirect_to @household,
                  alert: "Only an admin can remove roommates."
    when :cannot_remove_self
      redirect_to @household,
                  alert: "You cannot remove yourself. Use Leave Household."
    when :cannot_remove_admin
      redirect_to @household,
                  alert: "You cannot remove another admin."
    end
  end

  private

  def set_household
    @household = current_user.households.find(params[:household_id])
  end
end
