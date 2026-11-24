require "rails_helper"

RSpec.describe "Chore recurrence boundaries" do
  let!(:user) { User.create!(name: "Member", email: "recurrence@example.com", password: "password123") }
  let!(:household) { Household.create!(name: "Recurrence house", creator: user) }

  [
    [ "DAILY", "2026-11-01 09:00", "2026-11-02 12:00", "2026-11-03 23:59", "2026-11-03 09:00" ],
    [ "WEEKLY", "2026-11-01 09:00", "2026-11-08 12:00", "2026-11-15 23:59", "2026-11-15 09:00" ],
    [ "MONTHLY", "2026-01-31 09:00", "2026-02-28 12:00", "2026-03-31 23:59", "2026-03-31 09:00" ]
  ].each do |frequency, start, from, to, expected|
    it "does not duplicate a #{frequency.downcase} occurrence after aligning the range" do
      chore = household.chores.create!(title: "Shared chore", creator: user,
                                      frequency: frequency, due_at: Time.zone.parse(start))
      chore.chore_assignments.create!(user: user)
      result = CalendarService.new.chores_for(household, from: Time.zone.parse(from), to: Time.zone.parse(to))
      expect(result.map(&:start_timestamp)).to eq([ Time.zone.parse(expected) ])
    end
  end

  [
    [ "DAILY", "2026-11-01 09:00", "2026-11-05 12:00", "2026-11-05 09:00" ],
    [ "WEEKLY", "2026-11-01 09:00", "2026-11-09 12:00", "2026-11-15 09:00" ],
    [ "MONTHLY", "2026-01-31 09:00", "2026-03-05 12:00", "2026-03-31 09:00" ]
  ].each do |frequency, start, now, expected|
    it "agrees with the calendar on the next #{frequency.downcase} date shown on the chores page" do
      chore = household.chores.create!(title: "Shared chore", creator: user,
                                      frequency: frequency, due_at: Time.zone.parse(start))
      chore.chore_assignments.create!(user: user)
      now = Time.zone.parse(now)
      calendar_next = CalendarService.new.chores_for(household, from: now.beginning_of_day, to: now + 40.days)
                                     .map(&:start_timestamp).min

      expect(chore.next_due_at(now)).to eq(Time.zone.parse(expected))
      expect(chore.next_due_at(now)).to eq(calendar_next)
    end
  end
end
