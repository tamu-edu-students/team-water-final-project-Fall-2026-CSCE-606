require "rails_helper"

RSpec.describe "Household search", type: :request do
  let!(:owner) { User.create!(name: "Owner", email: "owner@example.com", password: "password123") }
  let!(:user) { User.create!(name: "Searcher", email: "searcher@example.com", password: "password123") }
  let!(:household) { Household.create!(name: "Water House", creator: owner) }

  before do
    household.household_memberships.create!(user: owner, role: "admin")
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "finds partial names regardless of case and trims whitespace" do
    get join_household_path, params: { q: "  wAtEr  " }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Water House", "household_id=#{household.id}")
    expect(response.body).not_to include(household.invite_code, owner.email)
  end

  it "does not list households before a search or for blank input" do
    [nil, "   "].each do |query|
      get join_household_path, params: { q: query }
      expect(response.body).not_to include("Water House")
    end
  end

  it "explains when no names match" do
    get join_household_path, params: { q: "Missing" }
    expect(response.body).to include("No households found")
  end

  it "treats SQL wildcard characters literally" do
    special = Household.create!(name: "100%_Home", creator: owner)
    get join_household_path, params: { q: "%_" }
    expect(response.body).to include(special.name)
    expect(response.body).not_to include("Water House")
  end

  it "excludes households the searcher already belongs to" do
    household.household_memberships.create!(user: user)
    get join_household_path, params: { q: "Water" }
    expect(response.body).not_to include("Water House")
    expect(response.body).to include("No households found")
  end

  it "limits results and prompts users to refine their query" do
    21.times { |i| Household.create!(name: "Match #{i.to_s.rjust(2, '0')}", creator: owner) }
    get join_household_path, params: { q: "Match" }
    document = Nokogiri::HTML(response.body)
    expect(document.css(".house-search-results li").size).to eq(20)
    expect(response.body).to include("Refine your search")
  end

  it "rejects overly long queries without listing households" do
    get join_household_path, params: { q: "x" * 101 }
    expect(response.body).to include("100 characters or fewer")
    expect(response.body).not_to include("Water House")
  end

  it "shows the selection without disclosing its invitation code" do
    get join_household_path, params: { household_id: household.id }
    expect(response.body).to include("Water House", 'name="household_id"')
    expect(response.body).not_to include(household.invite_code, owner.email)
  end

  it "joins the selected household using its matching code" do
    expect {
      post join_household_path, params: { household_id: household.id, invite_code: household.invite_code }
    }.to change { household.household_memberships.where(user: user).count }.by(1)
    expect(response).to have_http_status(:found)
    follow_redirect!
    follow_redirect! if response.redirect?
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Water House")
  end

  it "rejects a different household's valid code and retains the selection" do
    other = Household.create!(name: "Other House", creator: owner)
    expect {
      post join_household_path, params: { household_id: household.id, invite_code: other.invite_code }
    }.not_to change(HouseholdMembership, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Invalid invitation code.", "Water House", 'name="household_id"')
    expect(response.body).not_to include(other.invite_code)
  end

  it "requires a code even after selecting a household" do
    expect {
      post join_household_path, params: { household_id: household.id, invite_code: " " }
    }.not_to change(HouseholdMembership, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Please enter an invitation code.", "Water House")
  end

  it "does not duplicate an existing membership when a selection is resubmitted" do
    household.household_memberships.create!(user: user)
    expect {
      post join_household_path, params: { household_id: household.id, invite_code: household.invite_code }
    }.not_to change(HouseholdMembership, :count)
    expect(response).to have_http_status(:found)
    follow_redirect!
    follow_redirect! if response.redirect?
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Water House")
  end

  it "returns not found for a deleted selection rather than joining by code alone" do
    missing_id = household.id
    code = household.invite_code
    household.destroy!
    expect {
      post join_household_path, params: { household_id: missing_id, invite_code: code }
    }.not_to change(HouseholdMembership, :count)
    expect(response).to have_http_status(:not_found)
  end

  it "requires login for search, selection, and joining" do
    delete logout_path
    [{ q: "Water" }, { household_id: household.id }].each do |query|
      get join_household_path, params: query
      expect(response).to redirect_to(login_path)
    end
    expect {
      post join_household_path, params: { household_id: household.id, invite_code: household.invite_code }
    }.not_to change(HouseholdMembership, :count)
    expect(response).to redirect_to(login_path)
  end

  it "prefills a shared invitation link and binds the form to that household" do
    get join_household_path, params: { code: household.invite_code }
    document = Nokogiri::HTML(response.body)
    expect(document.at_css('input[name="invite_code"]')["value"]).to eq(household.invite_code)
    expect(document.at_css('input[name="household_id"]')["value"]).to eq(household.id.to_s)
    expect(response.body).to include("Water House", "You're invited to")
    expect {
      post join_household_path, params: {
        household_id: document.at_css('input[name="household_id"]')["value"],
        invite_code: document.at_css('input[name="invite_code"]')["value"]
      }
    }.to change { household.household_memberships.where(user: user).count }.by(1)
  end

  it "does not replace an explicit selection with another household's link code" do
    other = Household.create!(name: "Other Home", creator: owner)
    get join_household_path, params: { household_id: household.id, code: other.invite_code }
    document = Nokogiri::HTML(response.body)
    expect(document.at_css('input[name="household_id"]')["value"]).to eq(household.id.to_s)
    expect(response.body).not_to include("Other Home")
    expect {
      post join_household_path, params: { household_id: household.id, invite_code: other.invite_code }
    }.not_to change(HouseholdMembership, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end
end
