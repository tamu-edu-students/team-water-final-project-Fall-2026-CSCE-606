require "rails_helper"

RSpec.describe "Notification preferences", type: :request do
  let!(:user) do
    User.create!(
      name: "Test Roommate",
      email: "preferences@example.com",
      password: "password123"
    )
  end

  def login
    post login_path, params: {
      email: user.email,
      password: "password123"
    }
  end

  describe "GET /notification_preferences" do
    it "requires login" do
      get notification_preferences_path

      expect(response).to redirect_to(login_path)
    end

    it "displays the settings form" do
      login

      get notification_preferences_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Email Notification Preferences")
      expect(response.body).to include("Save Preferences")
    end

    it "does not create a record just by viewing settings" do
      login

      expect {
        get notification_preferences_path
      }.not_to change(NotificationPreference, :count)
    end
  end

  describe "PATCH /notification_preferences" do
    it "requires login" do
      patch notification_preferences_path, params: {
        notification_preference: { email_bills: "0" }
      }

      expect(response).to redirect_to(login_path)
      expect(NotificationPreference.count).to eq(0)
    end

    it "saves notification choices" do
      login

      patch notification_preferences_path, params: {
        notification_preference: {
          email_bills: "0",
          email_chores: "1",
          email_household_activity: "0"
        }
      }

      expect(response).to redirect_to(notification_preferences_path)

      preferences = user.reload.notification_preference
      expect(preferences.email_bills).to be(false)
      expect(preferences.email_chores).to be(true)
      expect(preferences.email_household_activity).to be(false)
    end

    it "updates existing preferences without duplicates" do
      user.create_notification_preference!(email_bills: false)
      login

      expect {
        patch notification_preferences_path, params: {
          notification_preference: { email_bills: "1" }
        }
      }.not_to change(NotificationPreference, :count)

      expect(user.reload.notification_preference.email_bills).to be(true)
    end

    it "cannot modify another user's preferences" do
      other = User.create!(
        name: "Other Roommate",
        email: "other-preferences@example.com",
        password: "password123"
      )
      other.create_notification_preference!(email_bills: true)
      login

      patch notification_preferences_path, params: {
        notification_preference: {
          user_id: other.id,
          email_bills: "0"
        }
      }

      expect(other.reload.notification_preference.email_bills).to be(true)
      expect(user.reload.notification_preference.email_bills).to be(false)
    end
  end
end
