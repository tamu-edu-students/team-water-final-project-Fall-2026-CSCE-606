class ShoppingItemsController < ApplicationController
  include InventoryPage

  before_action :require_login
  before_action :set_household
  before_action :set_item, only: %i[purchase destroy]

  def create
    @shopping_item = @household.shopping_items.new(item_params)
    @shopping_item.added_by = current_user

    if @shopping_item.save
      redirect_to shopping_list_path
    else
      @room = current_room
      @cart_open = true
      load_inventory
      render "inventory_items/index", status: :unprocessable_content
    end
  end

  def purchase
    @item.purchase!(current_user)
    redirect_to shopping_list_path
  end

  def destroy
    @item.destroy!
    redirect_to shopping_list_path
  end

  private

  # Only items still to buy can be bought or removed; bought items stay as history.
  def set_item
    @item = @household.shopping_items.to_buy.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def item_params
    params.require(:shopping_item).permit(:name, :quantity, :priority, :category, :inventory_item_id)
  end

  def current_room
    params[:room] if InventoryItem::ROOMS.key?(params[:room])
  end

  def shopping_list_path
    household_inventory_items_path(@household, room: current_room, cart: "open")
  end
end
