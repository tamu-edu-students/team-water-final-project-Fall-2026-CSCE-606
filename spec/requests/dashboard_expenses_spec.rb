require "rails_helper"

RSpec.describe "Dashboard expense summaries", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:member) { User.create!(name: "Member", email: "summary@example.com", password: "password123") }
  let!(:roommate) { User.create!(name: "Roommate", email: "creditor@example.com", password: "password123") }
  let!(:household) { Household.create!(name: "Summary House", creator: member) }

  before do
    [ member, roommate ].each { |user| household.household_memberships.create!(user: user) }
    post login_path, params: { email: member.email, password: "password123" }
  end

  def share(title:, amount: "12.34", owner: roommate, debtor: member, home: household, due: nil, status: "pending")
    expense = home.expenses.create!(title: title, amount: amount, expense_date: Date.current - 30,
                                   due_date: due, created_by: owner)
    expense.expense_participants.create!(user: debtor, amount_owed: amount, payment_status: status)
  end

  def card
    Nokogiri::HTML(response.body).at_css('[aria-labelledby="bills-heading"]')
  end

  it "does not call offsetting unpaid shares settled" do
    share(title: "Internet", amount: "30.00")
    share(title: "Groceries", amount: "30.00", owner: member, debtor: roommate)

    get household_dashboard_path(household)

    expect(card.at_css(".dashboard-status").text.squish).to eq("Payments pending")
    expect(card.text).to include("Net balance: $0.00", "Owed to you: $30.00", "You owe: $30.00")
    expect(card.text).not_to include("All settled up")
    expect(card.css("form").size).to eq(1)
  end

  it "shows gross obligations even when the net amount is owed to the user" do
    share(title: "Internet", amount: "10.10")
    share(title: "Groceries", amount: "40.40", owner: member, debtor: roommate)

    get household_dashboard_path(household)

    expect(card.text.squish).to include("Net balance: You are owed $30.30")
    expect(card.text).to include("Owed to you: $40.40", "You owe: $10.10")
    expect(card.text).to include("Net totals do not settle individual expense shares.")
  end

  it "includes overdue, today and day-five bills, excluding later, undated and paid shares" do
    travel_to(Time.zone.local(2026, 11, 10, 12)) do
      { "Overdue" => -1, "Today" => 0, "Day five" => 5, "Day six" => 6 }.each do |title, days|
        share(title: title, due: Date.current + days)
      end
      share(title: "Undated")
      share(title: "Already paid", due: Date.current, status: "paid")
      share(title: "Roommate's responsibility", due: Date.current, owner: member, debtor: roommate)

      get household_dashboard_path(household)

      titles = card.css(".dashboard-bills-due a").map(&:text)
      expect(titles).to eq([ "Overdue", "Today", "Day five" ])
      expect(card.text).to include("(overdue)")
    end
  end

  it "excludes another household even when the user belongs to both" do
    other = Household.create!(name: "Other House", creator: member)
    [ member, roommate ].each { |user| other.household_memberships.create!(user: user) }
    share(title: "Private other bill", amount: "999.99", home: other, due: Date.current)
    share(title: "Selected household bill", amount: "12.34", due: Date.current)

    get household_dashboard_path(household)

    expect(card.text).to include("You owe: $12.34", "Selected household bill")
    expect(card.text).not_to include("Private other bill", "999.99")
  end

  it "only calls a balance settled when no payable or receivable amount remains" do
    share(title: "Paid internet", status: "paid")
    share(title: "My own share", owner: member)

    get household_dashboard_path(household)

    expect(card.at_css(".dashboard-status").text.squish).to eq("Settled up")
    expect(card.text).to include("All settled up", "Nothing pending for you")
    expect(card.css("form")).to be_empty
  end
end
