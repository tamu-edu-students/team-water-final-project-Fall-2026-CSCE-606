class InventoryItemsController < ApplicationController
  before_action :require_login
  before_action :set_household
  before_action :set_item, only: %i[update destroy adjust]

  def index
    @household.ensure_default_inventory!
    @room = params[:room] if InventoryItem::ROOMS.key?(params[:room])
    @editing_id = params[:edit].to_i
    load_inventory
  end

  def create
    @new_item = @household.inventory_items.new(item_params)
    unless InventoryItem::ROOMS.key?(@new_item.room)
      return redirect_to household_inventory_items_path(@household), alert: "Choose a room first."
    end

    if @new_item.save
      redirect_to room_inventory_path(@new_item.room),
                  notice: "#{@new_item.name} added to #{@new_item.room_label}."
    else
      @room = @new_item.room
      load_inventory
      render :index, status: :unprocessable_content
    end
  end

  def update
    if @item.update(item_params.except(:room))
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
    @item.destroy!
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
    end
    redirect_to room_inventory_path(@item.room)
  end

  private

  def set_household
    @household = current_user.households.find(params[:household_id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def set_item
    @item = @household.inventory_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def item_params
    params.require(:inventory_item).permit(:name, :quantity, :room)
  end

  def load_inventory
    items = @household.inventory_items
    @room_counts = items.group(:room).count
    @out_of_stock_counts = items.out_of_stock.group(:room).count
    @items = @room ? items.where(room: @room).order(Arel.sql("lower(name)")) : []
    @new_item ||= InventoryItem.new(household: @household, room: @room, quantity: 1)
  end

  def room_inventory_path(room)
    household_inventory_items_path(@household, room:)
  end
end
