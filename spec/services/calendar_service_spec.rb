require "rails_helper"

RSpec.describe CalendarService do
  let(:creator) do
    User.create!(
      name: "Aditi",
      email: "aditi@example.com",
      password: "password123"
    )
  end
  let(:household) do
    Household.create!(name: "Apartment 101", creator: creator).tap do |record|
      HouseholdMembership.create!(household: record, user: creator)
    end
  end

  def create_event(attributes = {})
    household.events.create!(
      {
        creator: creator,
        name: "House meeting",
        start_timestamp: Time.zone.parse("2026-11-03 18:00"),
        end_timestamp: Time.zone.parse("2026-11-03 19:00"),
        recurring: "DAILY"
      }.merge(attributes)
    )
  end

  it "expands daily occurrences and preserves their original start" do
    event = create_event

    occurrences = described_class.new.events_for(
      household,
      from: Time.zone.parse("2026-11-04 00:00"),
      to: Time.zone.parse("2026-11-05 23:59")
    )

    expect(occurrences.map(&:original_start)).to eq(
      [Time.zone.parse("2026-11-04 18:00"), Time.zone.parse("2026-11-05 18:00")]
    )
    expect(occurrences.map(&:event_id).uniq).to eq([event.id])
  end

  it "applies occurrence changes and omits cancelled occurrences" do
    event = create_event
    moved_start = Time.zone.parse("2026-11-04 20:00")
    event.event_exceptions.create!(
      original_start: Time.zone.parse("2026-11-04 18:00"),
      start_timestamp: moved_start,
      end_timestamp: moved_start + 1.hour
    )
    event.event_exceptions.create!(
      original_start: Time.zone.parse("2026-11-05 18:00"),
      is_cancelled: true
    )

    occurrences = described_class.new.events_for(
      household,
      from: Time.zone.parse("2026-11-04 00:00"),
      to: Time.zone.parse("2026-11-05 23:59")
    )

    expect(occurrences.map(&:start_timestamp)).to eq([moved_start])
    expect(occurrences.first.original_start).to eq(Time.zone.parse("2026-11-04 18:00"))
  end

  it "includes a series when an occurrence was moved into the requested range" do
    event = create_event(recurrence_until: Date.new(2026, 11, 5))
    original_start = Time.zone.parse("2026-11-04 18:00")
    moved_start = Time.zone.parse("2026-11-10 18:00")
    event.event_exceptions.create!(
      original_start:,
      start_timestamp: moved_start,
      end_timestamp: moved_start + 1.hour
    )

    occurrences = described_class.new.events_for(
      household,
      from: Time.zone.parse("2026-11-10 00:00"),
      to: Time.zone.parse("2026-11-10 23:59")
    )

    expect(occurrences.map(&:original_start)).to eq([original_start])
    expect(occurrences.map(&:start_timestamp)).to eq([moved_start])
  end

  it "returns chore due dates for assigned members and expands recurring chores" do
    roommate = User.create!(
      name: "Roommate",
      email: "roommate@example.com",
      password: "password123"
    )
    HouseholdMembership.create!(household:, user: roommate)
    chore = household.chores.create!(
      creator: creator,
      title: "Take out trash",
      due_at: Time.zone.parse("2026-11-03 17:00"),
      frequency: "WEEKLY"
    )
    chore.chore_assignments.create!(user: roommate)

    occurrences = described_class.new.calendar_items_for(
      household,
      from: Time.zone.parse("2026-11-01 00:00"),
      to: Time.zone.parse("2026-11-30 23:59"),
      user_id: roommate.id
    )

    expect(occurrences.map(&:type).uniq).to eq([:chore])
    expect(occurrences.map(&:name).uniq).to eq(["Take out trash"])
    expect(occurrences.map { |occurrence| occurrence.start_timestamp.to_date }).to eq(
      [Date.new(2026, 11, 3), Date.new(2026, 11, 10), Date.new(2026, 11, 17), Date.new(2026, 11, 24)]
    )
    expect(occurrences.map(&:chore_id).uniq).to eq([chore.id])
  end

  it "does not show a chore to a household member who is not assigned" do
    roommate = User.create!(
      name: "Roommate",
      email: "roommate@example.com",
      password: "password123"
    )
    HouseholdMembership.create!(household:, user: roommate)
    chore = household.chores.create!(
      creator: creator,
      title: "Clean kitchen",
      due_at: Time.zone.parse("2026-11-03 17:00"),
      frequency: "NONE"
    )
    chore.chore_assignments.create!(user: creator)

    occurrences = described_class.new.calendar_items_for(
      household,
      from: Time.zone.parse("2026-11-01 00:00"),
      to: Time.zone.parse("2026-11-30 23:59"),
      user_id: roommate.id
    )

    expect(occurrences).to be_empty
  end

  it "accepts additional timestamped calendar item types without source-specific logic" do
    items = described_class.new.calendar_items_for(
      household,
      from: Time.zone.parse("2026-11-01 00:00"),
      to: Time.zone.parse("2026-11-30 23:59"),
      additional_items: [
        {
          type: :bill,
          id: 21,
          name: "Water bill",
          due_at: Time.zone.parse("2026-11-15 09:00"),
          household_id: household.id,
          amount: "42.00"
        }
      ]
    )

    item = items.find { |calendar_item| calendar_item.type == :bill }
    expect(item).to have_attributes(
      id: 21,
      name: "Water bill",
      start_timestamp: Time.zone.parse("2026-11-15 09:00"),
      household_id: household.id
    )
    expect(item.attributes).to eq(amount: "42.00")
  end
end
