class NotificationPreferencesController < ApplicationController
  before_action :require_login
  before_action :set_preferences

  def show
  end

  def update
    if @notification_preference.update(preference_params)
      redirect_to notification_preferences_path,
                  notice: "Notification preferences saved successfully."
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_preferences
    @notification_preference =
      current_user.notification_preference ||
      current_user.build_notification_preference
  end

  def preference_params
    params.require(:notification_preference).permit(
      :email_bills,
      :email_chores,
      :email_household_activity
    )
  end
end
