class DashboardsController < ApplicationController
  before_action :require_login

  rescue_from ActiveRecord::RecordNotFound do
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def show
    # Scope the lookup before reading any household data, including member names.
    @household = current_user.households.find(params[:household_id])
    @members = @household.users.order(:name, :id).to_a
    @chores = @household.chores.includes(:assignees, :creator).order(:due_at, :title)
  end
end
