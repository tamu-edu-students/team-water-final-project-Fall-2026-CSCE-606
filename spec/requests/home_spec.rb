require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "redirects unauthenticated users to login" do
      get root_path

      expect(response).to redirect_to(login_path)
    end

    it "allows authenticated users to view the homepage" do
      user = User.create!(
        name: "Test User",
        email: "test@example.com",
        password: "password123"
      )

      post login_path, params: {
        email: user.email,
        password: "password123"
      }

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Welcome to Roommate OS!")
    end
  end
end
