require "rails_helper"

RSpec.describe "Dark mode theme support", type: :request do
  let!(:user) { User.create!(name: "Theme Tester", email: "theme@example.com", password: "password123") }
  let!(:household) { Household.create!(name: "Cozy Night House", creator: user) }

  before do
    household.household_memberships.create!(user: user, role: "admin")
  end

  def page
    Nokogiri::HTML(response.body)
  end

  def login
    post login_path, params: { email: user.email, password: "password123" }
  end

  describe "Anti-FOUC theme initialization script in layout" do
    it "includes the inline theme script in <head> on public pages" do
      get login_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("roommate_theme")
      expect(response.body).to include('document.documentElement.setAttribute("data-theme"')
    end

    it "includes the inline theme script in <head> on dashboard pages" do
      login
      get household_dashboard_path(household)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("roommate_theme")
      expect(response.body).to include('document.documentElement.setAttribute("data-theme"')
    end
  end

  describe "Theme toggle rendering" do
    it "renders the theme toggle button on the login page with accessibility attributes" do
      get login_path

      expect(response).to have_http_status(:ok)
      toggle = page.at_css(".theme-toggle-btn")
      expect(toggle).to be_present
      expect(toggle["data-controller"]).to eq("theme")
      expect(toggle["data-action"]).to eq("click->theme#toggle")
      expect(toggle["aria-label"]).to eq("Toggle dark mode")
      expect(toggle["aria-pressed"]).to eq("false")
      expect(toggle.at_css(".theme-icon-moon")).to be_present
      expect(toggle.at_css(".theme-icon-sun")).to be_present
    end

    it "renders the theme toggle button on the sign-up page" do
      get signup_path

      expect(response).to have_http_status(:ok)
      expect(page.at_css(".theme-toggle-btn")).to be_present
    end

    it "renders exactly one theme toggle button in the dashboard navigation header" do
      login
      get household_dashboard_path(household)

      expect(response).to have_http_status(:ok)
      toggles = page.css(".theme-toggle-btn")
      expect(toggles.size).to eq(1)

      nav_toggle = page.at_css(".dashboard-nav .theme-toggle-btn")
      expect(nav_toggle).to be_present
      expect(page.at_css(".dashboard-sidebar-footer .theme-toggle-btn")).to be_nil
    end

    it "renders the theme toggle on household onboarding / join pages" do
      login
      get new_household_path

      expect(response).to have_http_status(:ok)
      expect(page.at_css(".theme-toggle-btn")).to be_present
    end
  end
end
