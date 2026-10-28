require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) do
    User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123"
    )
  end

  describe "GET /login" do
    it "displays the login page" do
      get login_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Log in to Roommate OS")
    end
  end

  describe "POST /login" do
    it "logs in with valid credentials" do
      post login_path, params: {
        email: "test@example.com",
        password: "password123"
      }

      expect(response).to redirect_to(root_path)

      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Test User")
    end

    it "rejects incorrect passwords" do
      post login_path, params: {
        email: "test@example.com",
        password: "wrongpassword"
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Invalid email or password")
    end
  end

  describe "DELETE /logout" do
    it "logs out the user" do
      post login_path, params: {
        email: "test@example.com",
        password: "password123"
      }

      delete logout_path

      expect(response).to redirect_to(login_path)

      get root_path
      expect(response).to redirect_to(login_path)
    end
  end
end
