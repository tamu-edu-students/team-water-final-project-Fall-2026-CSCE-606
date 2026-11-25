require "rails_helper"

RSpec.describe "Chore categories", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:member) { User.create!(name: "Member", email: "categories@example.com", password: "password123") }
  let!(:household) { Household.create!(name: "Category House", creator: member) }

  before do
    travel_to Time.zone.local(2026, 11, 10, 12)
    household.household_memberships.create!(user: member)
    post login_path, params: { email: member.email, password: "password123" }
  end

  after { travel_back }

  def chore(title, category:, due: nil, frequency: "NONE")
    household.chores.create!(title:, category:, due_at: due, frequency:, creator: member).tap do |record|
      record.chore_assignments.create!(user: member)
    end
  end

  def page = Nokogiri::HTML(response.body)

  it "defaults new chores to General and rejects unknown categories" do
    expect(household.chores.create!(title: "Misc", creator: member).category).to eq("General")
    expect(household.chores.new(title: "Bad", creator: member, category: "Garage")).not_to be_valid
  end

  it "shows every chore with category filter chips for the categories in use" do
    chore("Wipe counters", category: "Kitchen")
    chore("Do dishes", category: "Kitchen")
    chore("Scrub tub", category: "Bathroom")

    get household_chores_path(household)

    chips = page.css(".chore-filter-chip").map { |chip| chip.text.squish }
    expect(chips).to eq([ "All 3", "🍳 Kitchen 2", "🛁 Bathroom 1" ])
    expect(page.at_css(".chore-filter-chip.is-active").text).to include("All")
    cards = page.css(".chore-card-list .chore-card")
    expect(cards.map { |card| card.at_css(".chore-card-title").text }).to contain_exactly("Wipe counters", "Do dishes", "Scrub tub")
    expect(cards.none? { |card| card["hidden"] }).to be(true)
    expect(page.at_css("#chore-search")).to be_present
  end

  it "filters to the requested category without JavaScript" do
    chore("Wipe counters", category: "Kitchen")
    tub = chore("Scrub tub", category: "Bathroom")

    get household_chores_path(household, category: "Bathroom")

    expect(page.at_css(".chore-filter-chip.is-active").text).to include("Bathroom")
    visible = page.css(".chore-card-list .chore-card").reject { |card| card["hidden"] }
    expect(visible.map { |card| card["id"] }).to eq([ "chore-#{tub.id}" ])
  end

  it "saves the chosen category when creating a chore" do
    post household_chores_path(household), params: {
      chore: { title: "Take out bins", category: "Trash", frequency: "NONE", assignee_ids: [ member.id ] }
    }
    expect(response).to redirect_to(household_chores_path(household))
    expect(household.chores.find_by!(title: "Take out bins").category).to eq("Trash")
  end

  it "lists pending chores (due today or past due) and upcoming dates for the next two weeks" do
    chore("Late chore", category: "General", due: 2.days.ago)
    chore("Today chore", category: "Kitchen", due: Time.current.change(hour: 18))
    chore("Soon chore", category: "General", due: 3.days.from_now)
    chore("Far chore", category: "General", due: 20.days.from_now)
    weekly = chore("Weekly bins", category: "Trash", due: Time.zone.local(2026, 10, 28, 18), frequency: "WEEKLY")

    get household_chores_path(household)

    pending = page.at_css(".chores-pending").css(".chore-schedule-title").map(&:text)
    expect(pending).to eq([ "Late chore", "Today chore" ])
    expect(page.at_css(".chores-pending .is-overdue").text).to include("Late chore", "late")

    upcoming = page.at_css(".chores-upcoming")
    expect(upcoming.css(".chore-schedule-title").map(&:text)).to eq([ "Weekly bins", "Soon chore" ])
    expect(upcoming.css(".chore-day-weekday").first.text).to eq("Tomorrow")
    expect(upcoming.text).not_to include("Far chore")

    stats = page.css(".chore-stat").to_h { |s| [ s.at_css(".chore-stat-label").text, s.at_css(".chore-stat-value").text ] }
    expect(stats).to include("Pending now" => "2", "Upcoming (14 days)" => "2", "Total chores" => "5", "Assigned to you" => "5")
    expect(weekly.next_due_at).to eq(Time.zone.local(2026, 11, 11, 18))
  end

  it "shows an empty pending state when nothing is due" do
    get household_chores_path(household)

    expect(page.at_css(".chores-pending").text).to include("Nothing pending")
    expect(page.at_css(".chores-upcoming").text).to include("No chores scheduled in the next two weeks.")
  end
end
