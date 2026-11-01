require "rails_helper"

RSpec.describe "Household dashboard", type: :request do
  let!(:user) { User.create!(name: "Bhaumik", email: "dashboard@example.com", password: "password123") }
  let!(:household) { Household.create!(name: "Water House", creator: user) }

  before { household.household_memberships.create!(user: user) }

  def login
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "requires login" do
    get household_dashboard_path(household)

    expect(response).to redirect_to(login_path)
  end

  it "shows the selected household and its members" do
    login
    get household_dashboard_path(household)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Water House", "Bhaumik", "1 member", "Household dashboard")
  end

  it "distinguishes unavailable summaries from the live bills summary" do
    login
    get household_dashboard_path(household)

    cards = Nokogiri::HTML(response.body).css(".dashboard-card")
    statuses = cards.to_h { |c| [ c.at_css("h2").text.strip, c.at_css(".dashboard-status").text.squish ] }

    expect(statuses).to eq(
      "Chores"               => "Not available yet",
      "Bills & balances"     => "Settled up",
      "Inventory alerts"     => "Not available yet",
      "House rules & voting" => "Not available yet"
    )

    unavailable = cards.reject { |c| c.at_css("h2").text.strip == "Bills & balances" }
    expect(unavailable.map(&:text).join).not_to include("$0.00")
    expect(response.body).not_to include("No upcoming tasks")
  end

  it "links to real household management and navigation pages" do
    login
    get household_dashboard_path(household)

    links = Nokogiri::HTML(response.body).css("a").map { |link| link["href"] }
    expect(links).to include(household_path(household), root_path, households_path)
    expect(links).not_to include("#", "/chores", "/bills", "/inventory", "/votes")
  end

  it "does not expose a non-member household or its invitation code" do
    private_household = Household.create!(name: "Private House", creator: user)
    login
    get household_dashboard_path(private_household)

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("Private House", private_household.invite_code)
  end

  it "returns not found for an unknown household" do
    login
    get household_dashboard_path(household.id + 10_000)

    expect(response).to have_http_status(:not_found)
  end

  it "revokes dashboard access immediately after membership removal" do
    login
    household.household_memberships.destroy_all
    get household_dashboard_path(household)

    expect(response).to have_http_status(:not_found)
  end

  it "keeps member data scoped when a user has multiple households" do
    second_household = Household.create!(name: "Second House", creator: user)
    second_household.household_memberships.create!(user: user)
    roommate = User.create!(name: "Second House Roommate", email: "second@example.com", password: "password123")
    second_household.household_memberships.create!(user: roommate)
    login
    get household_dashboard_path(household)

    expect(response.body).not_to include("Second House Roommate", second_household.invite_code)
    get household_dashboard_path(second_household)
    expect(response.body).to include("Second House Roommate", "2 members")
  end

  it "escapes household and member names" do
    household.update!(name: "<script>alert('house')</script>")
    user.update!(name: "<script>alert('member')</script>")
    login
    get household_dashboard_path(household)

    expect(response.body).to include("&lt;script&gt;")
    expect(response.body).not_to include(household.name, user.name)
  end

  it "links from household details to the dashboard" do
    login
    get household_path(household)

    expect(response.body).to include("href=\"#{household_dashboard_path(household)}\"")
  end

  it "offers only the current user's households on the home page" do
    Household.create!(name: "Unjoined House", creator: user)
    login
    get root_path

    expect(response.body).to include("Water House", household_dashboard_path(household))
    expect(response.body).not_to include("Unjoined House")
  end

  it "guides a user without a household to create or join one" do
    household.household_memberships.destroy_all
    login
    get root_path

    expect(response.body).to include("Create or join your first household")
    expect(response.body).to include("href=\"#{new_household_path}\"", "href=\"#{join_household_path}\"")
  end

  describe "expenses integration" do
    let!(:roommate) { User.create!(name: "Riley Roommate", email: "riley@example.com", password: "password123") }

    before { household.household_memberships.create!(user: roommate) }

    def create_expense(title:, amount:, paid_by:, in_household: household, **extra)
      Expense.create!(household: in_household, title: title, amount: amount, created_by: paid_by,
                      expense_date: Date.current, **extra)
            .tap { |e| e.split_equally([ user.id, roommate.id ]) }
    end

    def bills_card
      Nokogiri::HTML(response.body).css(".dashboard-card")
              .find { |c| c.at_css("h2").text.strip == "Bills & balances" }
    end

    it "shows what I owe, who I owe, and a link to the expense" do
      expense = create_expense(title: "Internet", amount: 60, paid_by: roommate)
      login
      get household_dashboard_path(household)

      expect(bills_card.at_css(".dashboard-status").text.squish).to eq("You owe")
      expect(bills_card.text).to include("You owe $30.00", "Riley Roommate")
      expect(bills_card.css("a").map { |a| a["href"] }).to include(household_expense_path(household, expense))
    end

    it "shows what I am owed and who owes me" do
      create_expense(title: "Groceries", amount: 90, paid_by: user)
      login
      get household_dashboard_path(household)

      expect(bills_card.at_css(".dashboard-status").text.squish).to eq("Owed to you")
      expect(bills_card.text).to include("You are owed $45.00", "Owed to you by", "Riley Roommate")
    end

    it "marks a share paid from the dashboard and returns settled" do
      expense = create_expense(title: "Internet", amount: 60, paid_by: roommate)
      share = expense.expense_participants.find_by!(user: user)
      mark_paid_path = mark_paid_household_expense_path(household, expense)

      login
      get household_dashboard_path(household)
      expect(bills_card.css("form[action='#{mark_paid_path}']")).not_to be_empty
      expect(bills_card.text).to include("Mark as Paid")

      patch mark_paid_path,
            params: { participant_id: share.id },
            headers: { "HTTP_REFERER" => household_dashboard_path(household) }

      expect(response).to redirect_to(household_dashboard_path(household))
      expect(share.reload.payment_status).to eq("paid")

      follow_redirect!
      expect(bills_card.at_css(".dashboard-status").text.squish).to eq("Settled up")
      puts bills_card.to_html
      expect(bills_card.css("form[action='#{mark_paid_path}']")).to be_empty
      expect(bills_card.text).not_to include("Mark as Paid")
    end

    it "lists bills that are due soon, including overdue ones" do
      create_expense(title: "Soon Bill", amount: 60, paid_by: roommate, due_date: Date.current + 2)
      create_expense(title: "Far Bill",  amount: 60, paid_by: roommate, due_date: Date.current + 30)
      login
      get household_dashboard_path(household)

      expect(bills_card.text).to include("Bills due in the next 5 days", "Soon Bill")
      expect(bills_card.css("ul").first.text).not_to include("Far Bill")
    end

    it "keeps expense data scoped to the selected household" do
      other = Household.create!(name: "Other House", creator: user)
      [ user, roommate ].each { |u| other.household_memberships.create!(user: u) }
      create_expense(title: "Elsewhere Bill", amount: 60, paid_by: roommate, in_household: other)
      login
      get household_dashboard_path(household)

      expect(response.body).not_to include("Elsewhere Bill")
      expect(bills_card.at_css(".dashboard-status").text.squish).to eq("Settled up")
    end

    it "links to the expense pages and escapes expense titles" do
      create_expense(title: "<script>alert('x')</script>", amount: 60, paid_by: roommate)
      login
      get household_dashboard_path(household)

      hrefs = Nokogiri::HTML(response.body).css("a").map { |a| a["href"] }
      expect(hrefs).to include(new_household_expense_path(household), household_expenses_path(household))
      expect(response.body).to include("&lt;script&gt;")
      expect(response.body).not_to include("<script>alert('x')</script>")
    end
  end
end
