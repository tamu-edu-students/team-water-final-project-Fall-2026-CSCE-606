require "rails_helper"

RSpec.describe "Password resets", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let!(:user) do
    User.create!(
      name: "Test User",
      email: "reset@example.com",
      password: "oldpassword123"
    )
  end

  describe "GET /password_reset/new" do
    it "displays the forgot password form" do
      get new_password_reset_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Forgot your password?")
    end
  end

  describe "POST /password_reset" do
    it "sends a reset email to a registered user" do
      expect do
        post password_reset_path,
             params: { email: user.email }
      end.to change {
        ActionMailer::Base.deliveries.size
      }.by(1)

      expect(response).to redirect_to(login_path)
    end

    it "does not reveal unregistered email addresses" do
      post password_reset_path,
           params: { email: "unknown@example.com" }

      expect(response).to redirect_to(login_path)
      expect(flash[:notice]).to include("If an account exists")
    end
  end

  describe "GET /password_reset/edit" do
    it "accepts a valid token" do
      get edit_password_reset_path(token: user.password_reset_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create a new password")
    end

    it "rejects an invalid token" do
      get edit_password_reset_path(token: "invalid")

      expect(response).to redirect_to(new_password_reset_path)
    end
  end

  describe "PATCH /password_reset" do
    it "changes the password and invalidates the reset token" do
      token = user.password_reset_token

      patch password_reset_path(token: token), params: {
        user: {
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }
      }

      expect(response).to redirect_to(login_path)
      expect(user.reload.authenticate("newpassword123")).to eq(user)
      expect(user.authenticate("oldpassword123")).to be_falsey
      expect(User.find_by_password_reset_token(token)).to be_nil
    end

    it "rejects mismatched passwords" do
      patch password_reset_path(token: user.password_reset_token),
            params: {
              user: {
                password: "newpassword123",
                password_confirmation: "different123"
              }
            }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.authenticate("oldpassword123")).to eq(user)
    end

    it "rejects an expired token" do
      token = user.password_reset_token

      travel 16.minutes do
        patch password_reset_path(token: token), params: {
          user: {
            password: "newpassword123",
            password_confirmation: "newpassword123"
          }
        }

        expect(response).to redirect_to(new_password_reset_path)
      end

      expect(user.reload.authenticate("oldpassword123")).to eq(user)
    end
  end
end
