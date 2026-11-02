require "rails_helper"

RSpec.describe "Dashboard chore schedule", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:member) { User.create!(name: "Member", email: "schedule@example.com", password: "password123") }
  let!(:roommate) { User.create!(name: "Roommate", email: "schedule-roommate@example.com", password: "password123") }
  let!(:household) { Household.create!(name: "Schedule House", creator: member) }

  before do
    travel_to Time.zone.local(2026, 11, 10, 12)
    [ member, roommate ].each { |user| household.household_memberships.create!(user: user) }
    post login_path, params: { email: member.email, password: "password123" }
  end

  after { travel_back }

  def chore(title, due:, frequency: "NONE", home: household)
    home.chores.create!(title: title, due_at: due, frequency: frequency, creator: member).tap do |record|
      record.chore_assignments.create!(user: roommate)
    end
  end

  def schedule
    Nokogiri::HTML(response.body).at_css(".dashboard-chore-schedule")
  end

  it "includes today's and day-seven dates, but not past, day-eight, or undated chores" do
    chore("Earlier today", due: Time.current.beginning_of_day)
    chore("Day seven", due: 7.days.from_now.end_of_day)
    chore("Yesterday", due: 1.day.ago)
    chore("Day eight", due: 8.days.from_now)
    chore("No date", due: nil)

    get household_dashboard_path(household)

    expect(schedule.css("strong").map(&:text)).to eq([ "Earlier today", "Day seven" ])
    expect(schedule.text).to include("Roommate")
    expect(response.body).to include("Scheduled dates only; completion status is not tracked yet.")
  end

  it "uses the shared calendar recurrence for chores that began before this week" do
    chore("Weekly bins", due: Time.zone.local(2026, 10, 28, 18), frequency: "WEEKLY")

    get household_dashboard_path(household)

    expect(schedule.css("time").map { |time| time["datetime"] }).to eq([ Time.zone.local(2026, 11, 11, 18).iso8601 ])
  end

  it "keeps the summary bounded and shows the full count of scheduled dates" do
    chore("Daily dishes", due: Time.zone.local(2026, 10, 1, 18), frequency: "DAILY")

    get household_dashboard_path(household)

    expect(schedule.css("li").size).to eq(5)
    expect(response.body).to include("Showing the first 5 of 8 scheduled dates.")
  end

  it "does not expose chores from another household even when the user belongs to it" do
    other = Household.create!(name: "Other House", creator: member)
    other.household_memberships.create!(user: member)
    chore("Private other chore", due: Time.current, home: other)

    get household_dashboard_path(household)

    expect(schedule).to be_nil
    expect(response.body).to include("No chore dates scheduled from today through Nov 17")
    expect(response.body).not_to include("Private other chore")
  end

  it "refreshes after a chore changes and escapes user-provided titles" do
    item = chore("<script>unsafe</script>", due: Time.current)
    get household_dashboard_path(household)
    expect(schedule.text).to include("<script>unsafe</script>")
    expect(response.body).not_to include("<script>unsafe</script>")

    patch household_chore_path(household, item), params: {
      chore: { title: "Updated chore", due_at: 8.days.from_now.iso8601, assignee_ids: [ roommate.id ] }
    }
    expect(response).to redirect_to(household_chores_path(household))
    get household_dashboard_path(household)
    expect(schedule).to be_nil
  end
end
