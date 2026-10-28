require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "GET /signup" do
    it "displays the registration page" do
      get signup_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create your Roommate OS account")
    end
  end

  describe "POST /signup" do
    it "creates a user with valid information" do
      expect {
        post signup_path, params: {
          user: {
            name: "Test User",
            email: "test@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
    end

    it "rejects invalid registration information" do
      expect {
        post signup_path, params: {
          user: {
            name: "",
            email: "test@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
