require "rails_helper"

RSpec.describe "Household shopping list", type: :request do
  let!(:member) { User.create!(name: "Alice", email: "alice@example.com", password: "password123") }
  let!(:outsider) { User.create!(name: "David", email: "david@example.com", password: "password123") }
  let!(:household) do
    Household.create!(name: "Water House", creator: member).tap do |h|
      h.household_memberships.create!(user: member)
    end
  end
  let(:soap) { household.inventory_items.create!(room: "kitchen", name: "Dish soap", quantity: 0) }
  let(:milk) { household.shopping_items.create!(name: "Milk", quantity: 2, added_by: member) }

  def login_as(user)
    post login_path, params: { email: user.email, password: "password123" }
  end

  def shopping_list_path(room: "kitchen")
    household_inventory_items_path(household, room:, cart: "open")
  end

  def dialog
    Nokogiri::HTML(response.body).at_css("dialog.shopping-dialog")
  end

  describe "access" do
    it "redirects logged-out users to the login page" do
      post household_shopping_items_path(household), params: { shopping_item: { name: "Milk" } }
      expect(response).to redirect_to(login_path)
    end

    it "returns not found for non-members" do
      login_as(outsider)

      post household_shopping_items_path(household), params: { shopping_item: { name: "Milk" } }
      expect(response).to have_http_status(:not_found)

      patch purchase_household_shopping_item_path(household, milk)
      expect(response).to have_http_status(:not_found)
      expect(milk.reload.purchased_at).to be_nil
    end
  end

  describe "the popup" do
    before { login_as(member) }

    it "is closed until the cart button is used" do
      get household_inventory_items_path(household, room: "kitchen")

      expect(dialog).to be_nil
      cart = Nokogiri::HTML(response.body).at_css(".shopping-cart-button")
      expect(cart["href"]).to eq(shopping_list_path)
    end

    it "shows items to buy, low-stock suggestions, and purchase history" do
      milk
      soap
      household.shopping_items.create!(name: "Bread", added_by: member).purchase!(member)

      get shopping_list_path

      expect(dialog.at_css("#to-buy-heading").text).to eq("To buy (1)")
      expect(dialog.text).to include("Milk", "Added by Alice", "Dish soap", "Kitchen · 0 left", "Bought by Alice")
    end
  end

  describe "POST /households/:household_id/shopping" do
    before { login_as(member) }

    it "adds an item for the current member and reopens the popup" do
      post household_shopping_items_path(household),
           params: { room: "kitchen", shopping_item: { name: "Milk", quantity: 2, priority: "high", category: "Groceries" } }

      expect(response).to redirect_to(shopping_list_path)
      expect(household.shopping_items.last.slice(:name, :quantity, :priority, :added_by_id))
        .to eq("name" => "Milk", "quantity" => 2, "priority" => "high", "added_by_id" => member.id)
    end

    it "shows errors inside the popup" do
      milk
      post household_shopping_items_path(household), params: { room: "kitchen", shopping_item: { name: "milk" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(dialog.at_css(".inventory-errors").text).to include("Name is already on the shopping list")
    end
  end

  describe "PATCH /households/:household_id/shopping/:id/purchase" do
    before { login_as(member) }

    it "marks the item bought and restocks its inventory item" do
      item = household.shopping_items.create!(name: "Dish soap", quantity: 3, inventory_item: soap, added_by: member)

      patch purchase_household_shopping_item_path(household, item), params: { room: "kitchen" }

      expect(response).to redirect_to(shopping_list_path)
      expect(item.reload.purchased_by).to eq(member)
      expect(soap.reload.quantity).to eq(3)
    end

    it "cannot buy the same item twice" do
      milk.purchase!(member)

      patch purchase_household_shopping_item_path(household, milk)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /households/:household_id/shopping/:id" do
    before { login_as(member) }

    it "removes an item still to buy" do
      delete household_shopping_item_path(household, milk), params: { room: "kitchen" }

      expect(response).to redirect_to(shopping_list_path)
      expect(ShoppingItem.exists?(milk.id)).to be false
    end
  end
end
