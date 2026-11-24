require "rails_helper"

RSpec.describe InventoryActivity, type: :model do
  let(:alice) { User.create!(name: "Alice", email: "alice@example.com", password: "password123") }
  let(:bob) { User.create!(name: "Bob", email: "bob@example.com", password: "password123") }
  let(:household) { Household.create!(name: "Stock House", creator: alice) }
  let(:item) { household.inventory_items.create!(room: "kitchen", name: "Plates", quantity: 3) }

  def adjust(by, user = alice)
    item.update!(quantity: item.quantity + by)
    described_class.log_count_change(item, user)
  end

  describe ".log_snapshot" do
    it "keeps the item's name, room, count, and owner" do
      item.update!(owner: "Bob")
      activity = described_class.log_snapshot(item, alice, "removed")

      expect(activity.slice(:item_name, :room, :action)).to eq("item_name" => "Plates", "room" => "kitchen", "action" => "removed")
      expect(activity.change_lines).to eq([ "Count 3", "Owner Bob" ])
    end
  end

  describe ".log_changes" do
    it "records old and new values of tracked fields only" do
      item.update!(name: "Bowls", owner: "Alice", low_stock_threshold: 1, updated_at: 1.day.from_now)
      activity = described_class.log_changes(item, alice)

      expect(activity.details.keys).to contain_exactly("name", "owner", "low_stock_threshold")
      expect(activity.change_lines).to contain_exactly("Name Plates → Bowls", "Owner Shared → Alice", "Alert at 0 → 1")
    end

    it "logs nothing when no tracked field changed" do
      item.update!(name: "Plates")

      expect(described_class.log_changes(item, alice)).to be_nil
      expect(described_class.count).to eq(0)
    end
  end

  describe ".log_count_change" do
    it "merges quick clicks by the same person into one row" do
      adjust(-1)
      adjust(-1)

      expect(described_class.count).to eq(1)
      expect(described_class.last.change_lines).to eq([ "Count 3 → 1" ])
    end

    it "drops the row when the count ends where it started" do
      adjust(1)
      adjust(-1)

      expect(described_class.count).to eq(0)
    end

    it "starts a new row for another person or after the merge window" do
      adjust(1)
      adjust(1, bob)
      described_class.last.update!(updated_at: 10.minutes.ago)
      adjust(1, bob)

      expect(described_class.order(:id).map(&:change_lines)).to eq([ [ "Count 3 → 4" ], [ "Count 4 → 5" ], [ "Count 5 → 6" ] ])
    end

    it "does not merge into an edit that changed more than the count" do
      item.update!(name: "Bowls", quantity: 4)
      described_class.log_changes(item, alice)
      adjust(1)

      expect(described_class.count).to eq(2)
    end

    it "logs nothing when the count did not change" do
      item.update!(quantity: 3)

      expect(described_class.log_count_change(item, alice)).to be_nil
    end
  end

  it "keeps the history after the item is removed, and names a deleted user as a former roommate" do
    activity = described_class.log_snapshot(item, bob, "removed")
    item.destroy!
    bob.destroy!

    activity.reload
    expect(activity.inventory_item_id).to be_nil
    expect(activity.actor_name).to eq("Former roommate")
    expect(activity.room_label).to eq("Kitchen")
  end
end
