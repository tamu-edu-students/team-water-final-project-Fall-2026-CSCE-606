require "rails_helper"

RSpec.describe "Household inventory", type: :request do
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

  def kitchen_path
    household_inventory_items_path(household, room: "kitchen")
  end

  describe "access" do
    it "redirects logged-out users to the login page" do
      get household_inventory_items_path(household)
      expect(response).to redirect_to(login_path)
    end

    it "returns not found for non-members" do
      login_as(outsider)

      get household_inventory_items_path(household)
      expect(response).to have_http_status(:not_found)

      patch adjust_household_inventory_item_path(household, item), params: { delta: 1 }
      expect(response).to have_http_status(:not_found)
      expect(item.reload.quantity).to eq(1)
    end
  end

  describe "GET /households/:household_id/inventory" do
    before { login_as(member) }

    it "shows the room cards and asks to choose a room" do
      get household_inventory_items_path(household)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Living room", "Kitchen", "Bedroom", "Bathroom", "Patio")
      expect(response.body).to include("Choose a room to get started")
    end

    it "lists the default items of the selected room" do
      get kitchen_path

      names = Nokogiri::HTML(response.body).css(".inventory-item-name").map(&:text)
      expect(names).to eq(InventoryItem::DEFAULTS["kitchen"].keys.sort_by(&:downcase))
    end

    it "shows the inline edit form for the chosen item" do
      get household_inventory_items_path(household, room: "kitchen", edit: item.id)
      expect(response.body).to include("edit_item_#{item.id}_name")
    end
  end

  describe "POST /households/:household_id/inventory" do
    before { login_as(member) }

    it "adds an item to the room" do
      post household_inventory_items_path(household),
           params: { inventory_item: { room: "kitchen", name: "Paper towels", quantity: 3 } }

      expect(response).to redirect_to(kitchen_path)
      expect(household.inventory_items.find_by!(name: "Paper towels").quantity).to eq(3)
    end

    it "shows errors for an invalid item" do
      post household_inventory_items_path(household),
           params: { inventory_item: { room: "kitchen", name: "", quantity: -1 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Name can&#39;t be blank", "Count must be greater than or equal to 0")
    end

    it "refuses an unknown room" do
      post household_inventory_items_path(household),
           params: { inventory_item: { room: "garage", name: "Car", quantity: 1 } }

      expect(response).to redirect_to(household_inventory_items_path(household))
      expect(flash[:alert]).to eq("Choose a room first.")
    end
  end

  describe "PATCH /households/:household_id/inventory/:id" do
    before { login_as(member) }

    it "updates the name and count but not the room" do
      patch household_inventory_item_path(household, item),
            params: { inventory_item: { name: "Bowls", quantity: 4, room: "patio" } }

      expect(response).to redirect_to(kitchen_path)
      expect(item.reload.slice(:name, :quantity, :room)).to eq("name" => "Bowls", "quantity" => 4, "room" => "kitchen")
    end

    it "keeps the edit form open with errors" do
      household.inventory_items.create!(room: "kitchen", name: "Cups", quantity: 1)
      patch household_inventory_item_path(household, item), params: { inventory_item: { name: "cups" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Name already exists in this room")
      expect(item.reload.name).to eq("Plates")
    end
  end

  describe "PATCH /households/:household_id/inventory/:id/adjust" do
    before { login_as(member) }

    it "changes the count by one and never goes below zero" do
      patch adjust_household_inventory_item_path(household, item), params: { delta: 1 }
      expect(item.reload.quantity).to eq(2)

      3.times { patch adjust_household_inventory_item_path(household, item), params: { delta: -1 } }
      expect(item.reload.quantity).to eq(0)
    end

    it "ignores any other change" do
      patch adjust_household_inventory_item_path(household, item), params: { delta: 50 }

      expect(flash[:alert]).to eq("Invalid count change.")
      expect(item.reload.quantity).to eq(1)
    end
  end

  describe "DELETE /households/:household_id/inventory/:id" do
    before { login_as(member) }

    it "removes the item" do
      delete household_inventory_item_path(household, item)

      expect(response).to redirect_to(kitchen_path)
      expect(InventoryItem.exists?(item.id)).to be false
    end
  end

  describe "dashboard card" do
    before { login_as(member) }

    it "links to the inventory and lists out-of-stock items" do
      household.ensure_default_inventory!
      household.inventory_items.find_by!(name: "Dish soap").update!(quantity: 0)

      get household_dashboard_path(household)

      card = Nokogiri::HTML(response.body).at_css(".dashboard-inventory-card")
      expect(card["href"]).to eq(household_inventory_items_path(household))
      expect(card.at_css(".dashboard-status").text.squish).to eq("1 out of stock")
      expect(card.text).to include("Dish soap", "Kitchen · Out of stock")
    end
  end
end
