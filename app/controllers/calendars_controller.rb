class CalendarsController < ApplicationController
  before_action :require_logged_in_user
  before_action :set_household

  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def show
    from = parse_timestamp(params[:from], "from")
    to = parse_timestamp(params[:to], "to")
    raise ActionController::BadRequest, "to must be after from" if to < from

    items = CalendarService.new.calendar_items_for(@household, from:, to:).map do |item|
      if item.type == :event
        {
          type: "event",
          event_id: item.event_id,
          original_start: item.original_start.utc.iso8601,
          name: item.name,
          start_timestamp: item.start_timestamp.utc.iso8601,
          end_timestamp: item.end_timestamp.utc.iso8601
        }
      elsif item.type == :chore
        {
          type: "chore",
          id: item.chore_id,
          name: item.name,
          due_at: item.start_timestamp.utc.iso8601,
          assignee_ids: item.assignee_ids
        }
      else
        {
          type: item.type,
          id: item.id,
          name: item.name,
          start_timestamp: item.start_timestamp.utc.iso8601,
          end_timestamp: item.end_timestamp.utc.iso8601
        }.merge(item.attributes)
      end
    end
    render json: { items: }
  rescue ActionController::BadRequest => error
    render json: { error: error.message }, status: :bad_request
  end

  private

  def set_household
    @household = Household.find(params[:household_id])
    return if @household.household_memberships.exists?(user_id: current_user.id)

    render json: { error: "not a member of this household" }, status: :forbidden
  end

  def parse_timestamp(value, field)
    raise ActionController::BadRequest, "#{field} is required" if value.blank?

    Time.zone.iso8601(value)
  rescue ArgumentError, TypeError
    raise ActionController::BadRequest, "#{field} must be an ISO 8601 timestamp"
  end

  def render_bad_request(error)
    render json: { error: error.message }, status: :bad_request
  end

  def render_not_found
    render json: { error: "resource not found" }, status: :not_found
  end
end
