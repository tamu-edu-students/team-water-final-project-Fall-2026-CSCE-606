require "rails_helper"

# Guards the hand-off between the calendar and the redesigned chores page:
# categorised and template-created chores must still appear on the calendar,
# and calendar links must land on elements that exist on the chores page.
RSpec.describe "Chores and calendar integration", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:member) { User.create!(name: "Member", email: "chore-cal@example.com", password: "password123") }
  let!(:household) { Household.create!(name: "Calendar Chore House", creator: member) }

  before do
    travel_to Time.zone.local(2026, 11, 10, 12)
    household.household_memberships.create!(user: member)
    post login_path, params: { email: member.email, password: "password123" }
  end

  after { travel_back }

  def page = Nokogiri::HTML(response.body)

  def chore(title, category:, due:, frequency: "NONE")
    household.chores.create!(title:, category:, due_at: due, frequency:, creator: member).tap do |record|
      record.chore_assignments.create!(user: member)
    end
  end

  it "keeps categorised chores in the calendar feed and month view" do
    kitchen = chore("Wash the dishes", category: "Kitchen", due: Time.zone.local(2026, 11, 12, 18))
    chore("Take out the trash", category: "Trash", due: Time.zone.local(2026, 11, 4, 18), frequency: "WEEKLY")

    get "/households/#{household.id}/calendar", params: { from: "2026-11-01T00:00:00Z", to: "2026-11-30T23:59:59Z" }
    items = JSON.parse(response.body).fetch("items").select { |item| item["type"] == "chore" }
    expect(items.map { |item| item["name"] }.tally).to eq("Wash the dishes" => 1, "Take out the trash" => 4)
    expect(items.find { |item| item["name"] == "Wash the dishes" }["id"]).to eq(kitchen.id)

    get calendar_path, params: { month: "2026-11", view: "household", household_id: household.id }
    names = page.css(".dashboard-calendar-item--chore .dashboard-calendar-event-name").map(&:text)
    expect(names).to include("Wash the dishes", "Take out the trash")
  end

  it "links calendar chores to a visible card on the chores page" do
    kitchen = chore("Wash the dishes", category: "Kitchen", due: Time.zone.local(2026, 11, 12, 18))

    get calendar_path, params: { month: "2026-11", view: "household", household_id: household.id }
    link = page.css(".dashboard-calendar-item--chore a").find { |a| a.text == "Wash the dishes" }
    expect(link["href"]).to eq(household_chores_path(household, anchor: "chore-#{kitchen.id}"))

    get link["href"]
    card = page.at_css("#chore-#{kitchen.id}")
    expect(card).to be_present
    expect(card["hidden"]).to be_nil
  end

  it "lands the calendar's add-chore link on the prefilled add form" do
    get calendar_path, params: { month: "2026-11", view: "household", household_id: household.id }
    add_link = page.css(".dashboard-calendar-add-menu a").map { |a| a["href"] }
                   .find { |href| href.include?("due_on=2026-11-12") }
    expect(add_link).to eq(household_chores_path(household, due_on: "2026-11-12", anchor: "create-chore-heading"))

    get add_link
    expect(page.at_css("#create-chore-heading")).to be_present
    expect(page.at_css("#chore_due_at")["value"]).to start_with("2026-11-12T")
  end

  it "shows chores created from common chores (built-in or saved) on the calendar" do
    post household_chores_path(household), params: {
      chore: { title: "Feed the cat", category: "General", frequency: "DAILY",
               due_at: Time.zone.local(2026, 11, 11, 8).iso8601, assignee_ids: [ member.id ] },
      save_as_template: "1"
    }
    expect(household.chore_templates.pluck(:title)).to eq([ "Feed the cat" ])

    get "/households/#{household.id}/calendar", params: { from: "2026-11-11T00:00:00Z", to: "2026-11-13T23:59:59Z" }
    names = JSON.parse(response.body).fetch("items").filter_map { |item| item["name"] if item["type"] == "chore" }
    expect(names).to eq([ "Feed the cat" ] * 3)
  end

  it "shows the same next date on chore cards and upcoming list as the calendar" do
    monthly = chore("Clean out the fridge", category: "Kitchen", due: Time.zone.local(2026, 8, 31, 18), frequency: "MONTHLY")

    calendar_next = CalendarService.new.chores_for(household, from: Time.current.beginning_of_day,
                                                              to: 2.months.from_now).first.start_timestamp
    expect(monthly.next_due_at).to eq(calendar_next)
    expect(calendar_next).to eq(Time.zone.local(2026, 11, 30, 18))
  end
end
