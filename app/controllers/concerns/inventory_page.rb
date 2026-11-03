# Shared by the inventory and shopping list controllers, which render the same page.
module InventoryPage
  extend ActiveSupport::Concern

  private

  def set_household
    @household = current_user.households.find(params[:household_id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def load_inventory
    items = @household.inventory_items
    @room_counts = items.group(:room).count
    @low_stock_counts = items.low_stock.group(:room).count
    @items = @room ? items.where(room: @room).order(Arel.sql("lower(name)")) : []
    @new_item ||= InventoryItem.new(household: @household, room: @room, quantity: 1)

    @to_buy = @household.shopping_items.to_buy.includes(:added_by, :inventory_item).to_a
    @recently_bought = @household.shopping_items.purchased.includes(:purchased_by).limit(10)
    on_list = @to_buy.map { |item| item.name.downcase }
    @low_stock_suggestions = items.low_stock.order(:room, :name).reject { |item| on_list.include?(item.name.downcase) }
    @shopping_item ||= ShoppingItem.new(quantity: 1)
  end
end
