require "rails_helper"

RSpec.describe ShoppingItem, type: :model do
  let(:alice) { User.create!(name: "Alice", email: "alice@example.com", password: "password123") }
  let(:bob) { User.create!(name: "Bob", email: "bob@example.com", password: "password123") }
  let(:household) { Household.create!(name: "Stock House", creator: alice) }
  let(:soap) { household.inventory_items.create!(room: "kitchen", name: "Dish soap", quantity: 1) }

  def build_item(**attrs)
    household.shopping_items.new({ name: "Milk", quantity: 2, added_by: alice }.merge(attrs))
  end

  describe "validations" do
    it "is valid with a name, quantity, and the default priority and category" do
      item = build_item
      expect(item).to be_valid
      expect([ item.priority, item.category ]).to eq([ "normal", "Groceries" ])
    end

    it "requires a name and a quantity from 1 to the maximum" do
      expect(build_item(name: " ")).not_to be_valid
      expect(build_item(quantity: 0)).not_to be_valid
      expect(build_item(quantity: InventoryItem::MAX_QUANTITY + 1)).not_to be_valid
    end

    it "rejects unknown priorities and categories" do
      expect(build_item(priority: "urgent")).not_to be_valid
      expect(build_item(category: "Toys")).not_to be_valid
    end

    it "allows an item on the list only once until it is bought" do
      first = build_item.tap(&:save!)
      duplicate = build_item(name: "MILK")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("is already on the shopping list")

      first.purchase!(bob)
      expect(build_item(name: "milk")).to be_valid
    end

    it "only links inventory items from the same household" do
      other = Household.create!(name: "Other House", creator: alice)
      other_soap = other.inventory_items.create!(room: "kitchen", name: "Dish soap", quantity: 1)

      expect(build_item(inventory_item: soap)).to be_valid
      expect(build_item(inventory_item: other_soap)).not_to be_valid
    end
  end

  describe "#purchase!" do
    it "records who bought it and restocks the linked inventory item" do
      item = build_item(name: "Dish soap", quantity: 3, inventory_item: soap).tap(&:save!)

      item.purchase!(bob)

      expect(item.reload.purchased_by).to eq(bob)
      expect(item.purchased_at).to be_present
      expect(soap.reload.quantity).to eq(4)
    end

    it "does not change inventory for an unlinked item" do
      build_item.tap(&:save!).purchase!(bob)
      expect(soap.reload.quantity).to eq(1)
    end
  end

  it "lists items to buy by priority and keeps bought items as history" do
    low = build_item(name: "Napkins", priority: "low").tap(&:save!)
    high = build_item(name: "Bread", priority: "high").tap(&:save!)
    bought = build_item(name: "Eggs").tap(&:save!).tap { _1.purchase!(alice) }

    expect(household.shopping_items.to_buy).to eq([ high, low ])
    expect(household.shopping_items.purchased).to eq([ bought ])
  end
end
