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
end
