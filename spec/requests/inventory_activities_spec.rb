require "rails_helper"

RSpec.describe "Inventory history", type: :request do
  let!(:member) { User.create!(name: "Alice", email: "alice@example.com", password: "password123") }
  let!(:outsider) { User.create!(name: "David", email: "david@example.com", password: "password123") }
  let!(:household) do
    Household.create!(name: "Water House", creator: member).tap do |h|
      h.household_memberships.create!(user: member)
    end
  end
  let(:item) { household.inventory_items.create!(room: "kitchen", name: "Plates", quantity: 1) }

  def login_as(user)
    post login_path, params: { email: user.email, password: "password123" }
  end

  def history_rows(page = Nokogiri::HTML(response.body))
    page.css(".inventory-history-table tbody tr").map { |row| row.css("td").drop(1).map { |cell| cell.text.strip } }
  end

  describe "logging changes" do
    before { login_as(member) }

    it "logs adding, editing, and removing an item" do
      post household_inventory_items_path(household),
           params: { inventory_item: { room: "kitchen", name: "Blender", owner: "Alice", quantity: 2 } }
      blender = household.inventory_items.find_by!(name: "Blender")
      patch household_inventory_item_path(household, blender), params: { inventory_item: { name: "Mixer", quantity: 3 } }
      delete household_inventory_item_path(household, blender)

      get household_inventory_activities_path(household)
      expect(history_rows).to eq([
        [ "Alice", "Removed", "Mixer", "Kitchen", "Count 3 · Owner Alice" ],
        [ "Alice", "Updated", "Mixer", "Kitchen", "Name Blender → Mixer · Count 2 → 3" ],
        [ "Alice", "Added", "Blender", "Kitchen", "Count 2 · Owner Alice" ]
      ])
    end

    it "logs nothing for a save without changes, a failed save, or a count already at zero" do
      patch household_inventory_item_path(household, item), params: { inventory_item: { name: "Plates", quantity: 1 } }
      patch household_inventory_item_path(household, item), params: { inventory_item: { quantity: -5 } }
      patch adjust_household_inventory_item_path(household, item), params: { delta: -1 }
      patch adjust_household_inventory_item_path(household, item), params: { delta: -1 }

      expect(household.inventory_activities.map(&:change_lines)).to eq([ [ "Count 1 → 0" ] ])
    end

    it "merges quick +/- clicks into one row" do
      3.times { patch adjust_household_inventory_item_path(household, item), params: { delta: 1 } }

      expect(household.inventory_activities.map(&:change_lines)).to eq([ [ "Count 1 → 4" ] ])
    end

    it "logs a restock when a linked shopping item is bought" do
      plates = household.shopping_items.create!(name: "Plates", quantity: 5, added_by: member, inventory_item: item)
      patch purchase_household_shopping_item_path(household, plates)

      activity = household.inventory_activities.last
      expect([ activity.action, activity.change_lines ]).to eq([ "restocked", [ "Count 1 → 6" ] ])
    end
  end

  describe "room card" do
    before { login_as(member) }

    it "links every room to the same full history without listing changes" do
      InventoryActivity.log_snapshot(item, member, "added")

      %w[kitchen patio].each do |room|
        get household_inventory_items_path(household, room:)
        card = Nokogiri::HTML(response.body).at_css(".inventory-history-card")

        expect(card.text.squish).to eq("Item history See every change, in every room. View full history")
        expect(card.at_css("a")["href"]).to eq(household_inventory_activities_path(household))
      end
    end
  end

  describe "GET /households/:household_id/inventory/history" do
    it "requires a login and household membership" do
      get household_inventory_activities_path(household)
      expect(response).to redirect_to(login_path)

      login_as(outsider)
      get household_inventory_activities_path(household)
      expect(response).to have_http_status(:not_found)
    end

    it "filters by room and shows an empty state" do
      login_as(member)
      InventoryActivity.log_snapshot(item, member, "added")

      get household_inventory_activities_path(household, room: "patio")
      expect(response.body).to include("No changes in the patio yet.")
      expect(Nokogiri::HTML(response.body).at_css(".inventory-history-filters a[aria-current]").text).to eq("Patio")

      get household_inventory_activities_path(household, room: "garage")
      expect(history_rows.map(&:third)).to eq([ "Plates" ])
    end

    it "pages through older changes" do
      login_as(member)
      (InventoryActivitiesController::PER_PAGE + 1).times { InventoryActivity.log_snapshot(item, member, "added") }

      get household_inventory_activities_path(household)
      expect(history_rows.size).to eq(InventoryActivitiesController::PER_PAGE)
      expect(response.body).to include("Older →")
      expect(response.body).not_to include("← Newer")

      get household_inventory_activities_path(household, page: 2)
      expect(history_rows.size).to eq(1)
      expect(response.body).to include("← Newer")
    end
  end
end
