class InventoryItemsController < ApplicationController
  include InventoryPage

  before_action :require_login
  before_action :set_household
  before_action :set_item, only: %i[update destroy adjust]

  # Raised when locking an item that a roommate removed after this request loaded it.
  rescue_from ActiveRecord::RecordNotFound, with: :item_already_removed

  def index
    @household.ensure_default_inventory!
    @room = params[:room] if InventoryItem::ROOMS.key?(params[:room])
    @editing_id = params[:edit].to_i
    @cart_open = params[:cart] == "open"
    load_inventory
  end

  def create
    @new_item = @household.inventory_items.new(item_params)
    unless InventoryItem::ROOMS.key?(@new_item.room)
      return redirect_to household_inventory_items_path(@household), alert: "Choose a room first."
    end

    saved = InventoryItem.transaction do
      @new_item.save.tap { |ok| InventoryActivity.log_snapshot(@new_item, current_user, "added") if ok }
    end

    if saved
      redirect_to room_inventory_path(@new_item.room),
                  notice: "#{@new_item.name} added to #{@new_item.room_label}."
    else
      @room = @new_item.room
      load_inventory
      render :index, status: :unprocessable_content
    end
  end

  def update
    # The lock reloads the item, so the history starts from the latest saved values.
    updated = @item.with_lock do
      @item.update(item_params.except(:room)).tap { |ok| InventoryActivity.log_changes(@item, current_user) if ok }
    end

    if updated
      redirect_to room_inventory_path(@item.room), notice: "#{@item.name} updated."
    else
      @room = @item.room
      @editing_id = @item.id
      @editing_item = @item
      load_inventory
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    @item.with_lock do
      InventoryActivity.log_snapshot(@item, current_user, "removed")
      @item.destroy!
    end
    redirect_to room_inventory_path(@item.room),
                notice: "#{@item.name} removed from #{@item.room_label}."
  end

  def adjust
    delta = params[:delta].to_s
    unless %w[1 -1].include?(delta)
      return redirect_to room_inventory_path(@item.room), alert: "Invalid count change."
    end

    @item.with_lock do
      @item.update!(quantity: (@item.quantity + delta.to_i).clamp(0, InventoryItem::MAX_QUANTITY))
      InventoryActivity.log_count_change(@item, current_user)
    end
    redirect_to room_inventory_path(@item.room)
  end

  private

  def set_item
    @item = @household.inventory_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def item_already_removed
    redirect_to room_inventory_path(@item.room), alert: "#{@item.name} was already removed by someone else."
  end

  def item_params
    params.require(:inventory_item).permit(:name, :owner, :quantity, :low_stock_threshold, :room)
  end

  def room_inventory_path(room)
    household_inventory_items_path(@household, room:)
  end
end
