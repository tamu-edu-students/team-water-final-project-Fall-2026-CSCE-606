require "uri"

class HouseholdInvitationsController < ApplicationController
  before_action :require_login
  before_action :set_household
  before_action :require_admin

  rate_limit to: 20, within: 1.hour,
             by: -> { "#{current_user.id}:#{@household.id}" },
             only: :create

  def create
    email = params[:email].to_s.strip.downcase

    if email.blank? || email.length > 254 ||
       !URI::MailTo::EMAIL_REGEXP.match?(email)
      return redirect_to @household,
                         alert: "Please enter a valid email address."
    end

    if @household.users.exists?(email: email)
      return redirect_to @household,
                         alert: "This roommate is already a member."
    end

    HouseholdInvitationMailer.invite(
      email: email,
      household: @household,
      invited_by: current_user
    ).deliver_now

    redirect_to @household,
                notice: "Invitation email processed successfully."
  end

  private

  def set_household
    @household = current_user.households.find(
      params[:household_id]
    )
  end

  def require_admin
    return if @household.admin?(current_user)

    redirect_to @household,
                alert: "Only an admin can send invitations."
  end
end
