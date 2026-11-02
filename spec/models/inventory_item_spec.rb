require "rails_helper"

RSpec.describe InventoryItem, type: :model do
  let(:creator) { User.create!(name: "Alice", email: "alice@example.com", password: "password123") }
  let(:household) { Household.create!(name: "Stock House", creator: creator) }

  def build_item(**attrs)
    household.inventory_items.new({ room: "kitchen", name: "Plates", quantity: 2 }.merge(attrs))
  end

  describe "validations" do
    it "is valid with a room, name, and count" do
      expect(build_item).to be_valid
    end

    it "rejects unknown rooms" do
      expect(build_item(room: "garage")).not_to be_valid
    end

    it "requires a name of at most 100 characters" do
      expect(build_item(name: " ")).not_to be_valid
      expect(build_item(name: "a" * 101)).not_to be_valid
    end

    it "squishes extra whitespace in the name" do
      expect(build_item(name: "  Paper   towels ").name).to eq("Paper towels")
    end

    it "only allows whole counts from 0 to the maximum" do
      expect(build_item(quantity: 0)).to be_valid
      expect(build_item(quantity: InventoryItem::MAX_QUANTITY)).to be_valid
      expect(build_item(quantity: -1)).not_to be_valid
      expect(build_item(quantity: InventoryItem::MAX_QUANTITY + 1)).not_to be_valid
      expect(build_item(quantity: "2.5")).not_to be_valid
    end

    it "rejects a duplicate name in the same room, ignoring case" do
      build_item.save!
      duplicate = build_item(name: "PLATES")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("already exists in this room")
    end

    it "allows the same name in another room or household" do
      build_item.save!
      other = Household.create!(name: "Other House", creator: creator)

      expect(build_item(room: "patio")).to be_valid
      expect(other.inventory_items.new(room: "kitchen", name: "Plates", quantity: 1)).to be_valid
    end
  end

  describe "Household#ensure_default_inventory!" do
    let(:default_count) { InventoryItem::DEFAULTS.values.sum(&:size) }

    it "adds the default items for every room only once" do
      2.times { household.ensure_default_inventory! }

      expect(household.inventory_items.count).to eq(default_count)
      expect(household.inventory_items.distinct.pluck(:room)).to match_array(InventoryItem::ROOMS.keys)
    end

    it "does not bring back a deleted default item" do
      household.ensure_default_inventory!
      household.inventory_items.find_by!(name: "Sofa").destroy!

      Household.find(household.id).ensure_default_inventory!

      expect(household.inventory_items.exists?(name: "Sofa")).to be false
    end
  end
end
