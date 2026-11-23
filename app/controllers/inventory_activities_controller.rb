# Full inventory history for a household, newest first, optionally for one room.
class InventoryActivitiesController < ApplicationController
  include InventoryPage

  PER_PAGE = 50

  before_action :require_login
  before_action :set_household

  def index
    @room = params[:room] if InventoryItem::ROOMS.key?(params[:room])
    @page = [ params[:page].to_i, 1 ].max

    activities = @household.inventory_activities.includes(:user).recent_first
    activities = activities.where(room: @room) if @room
    @activities = activities.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
    @next_page = @page + 1 if @activities.size > PER_PAGE
    @activities = @activities.first(PER_PAGE)
  end
end
