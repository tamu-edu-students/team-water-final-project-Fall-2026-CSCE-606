class EventsController < ApplicationController
  before_action :require_logged_in_user
  before_action :set_household, only: %i[index create]
  before_action :set_event, only: %i[update destroy]
  before_action :authorize_event_management, only: %i[update destroy]

  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def index
    from, to = calendar_range
    user_id = params[:user_id]
    if user_id.present?
      begin
        user_id = Integer(user_id)
      rescue ArgumentError, TypeError
        raise ActionController::BadRequest, "user_id must be an integer"
      end
      if !@household.household_memberships.exists?(user_id: user_id)
        raise ActionController::BadRequest, "user_id must be a household member"
      end
    end

    render json: {
      events: CalendarService.new.events_for(@household, from:, to:, user_id:).map { |event| event_json(event) }
    }
  rescue ActionController::BadRequest => error
    render json: { error: error.message }, status: :bad_request
  end

  def create
    event = @household.events.new(event_params.except(:attendee_ids))
    event.creator = current_user
    attendee_ids = parsed_attendee_ids

    unless (attendee_ids - household_member_ids).empty?
      return render json: { error: "attendee_ids must be household members" }, status: :bad_request
    end

    Event.transaction do
      event.save!
      attendee_ids.each { |user_id| event.event_attendees.create!(user_id:) }
    end
    render json: event_json(event), status: :created
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: error.record.errors.full_messages.to_sentence }, status: :bad_request
  rescue ActionController::BadRequest => error
    render json: { error: error.message }, status: :bad_request
  end

  def update
    scope = params[:scope].presence || "all"
    return render json: { error: "scope must be all or this" }, status: :bad_request unless %w[all this].include?(scope)

    if @event.recurring == "NONE"
      return update_single_event
    end

    return update_occurrence if scope == "this"

    attributes = event_params
    attendee_ids = attributes.delete(:attendee_ids)
    new_attendee_ids = parsed_attendee_ids
    if attendee_ids && !(new_attendee_ids - household_member_ids).empty?
      return render json: { error: "attendee_ids must be household members" }, status: :bad_request
    end

    Event.transaction do
      @event.update!(attributes)
      replace_attendees(new_attendee_ids) if attendee_ids
    end
    render json: event_json(@event)
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: error.record.errors.full_messages.to_sentence }, status: :bad_request
  rescue ActionController::BadRequest => error
    render json: { error: error.message }, status: :bad_request
  end

  def destroy
    scope = params[:scope].presence || "all"
    return render json: { error: "scope must be all or this" }, status: :bad_request unless %w[all this].include?(scope)

    if scope == "this" && @event.recurring != "NONE"
      occurrence_start = parse_timestamp(params[:occurrence_start], "occurrence_start")
      unless CalendarService.new.occurrence?(@event, occurrence_start)
        return render json: { error: "occurrence_start is not an occurrence of this event" }, status: :bad_request
      end

      exception = @event.event_exceptions.find_or_initialize_by(original_start: occurrence_start)
      exception.update!(is_cancelled: true, name: nil, description: nil,
                        start_timestamp: nil, end_timestamp: nil)
    else
      @event.destroy!
    end
    head :no_content
  rescue ActionController::BadRequest => error
    render json: { error: error.message }, status: :bad_request
  end

  private

  def set_household
    @household = Household.find(params[:household_id])
    return if household_member?

    render json: { error: "not a member of this household" }, status: :forbidden
  end

  def set_event
    @event = Event.find(params[:id])
    @household = @event.household
    return if household_member?

    render json: { error: "not a member of this household" }, status: :forbidden
  end

  def authorize_event_management
    return if @event.created_by == current_user.id
    return if @household.admin?(current_user)

    render json: { error: "only the creator or a household admin can change this event" }, status: :forbidden
  end

  def household_member?
    @household.household_memberships.exists?(user_id: current_user.id)
  end

  def event_params
    attributes = params.permit(:name, :description, :start_timestamp, :end_timestamp, :all_day,
                               :recurring, :recurrence_until, attendee_ids: []).to_h.symbolize_keys
    if attributes.key?(:all_day) && ![true, false].include?(attributes[:all_day])
      raise ActionController::BadRequest, "all_day must be a boolean"
    end
    %i[start_timestamp end_timestamp].each do |field|
      attributes[field] = parse_timestamp(attributes[field], field) if attributes.key?(field)
    end
    if attributes[:recurrence_until].present?
      begin
        attributes[:recurrence_until] = Date.iso8601(attributes[:recurrence_until])
      rescue Date::Error, TypeError
        raise ActionController::BadRequest, "recurrence_until must be an ISO 8601 date"
      end
    end
    attributes
  end

  def parsed_attendee_ids
    if params.key?(:attendee_ids) && !params[:attendee_ids].is_a?(Array)
      raise ActionController::BadRequest, "attendee_ids must be an array"
    end

    raw_ids = event_params[:attendee_ids] || []
    raw_ids.map { |id| Integer(id) }.uniq
  rescue ArgumentError, TypeError
    raise ActionController::BadRequest, "attendee_ids must contain integers"
  end

  def household_member_ids
    @household.user_ids
  end

  def replace_attendees(user_ids)
    @event.event_attendees.delete_all
    user_ids.each { |user_id| @event.event_attendees.create!(user_id:) }
  end

  def update_single_event
    attributes = event_params
    attendee_ids = parsed_attendee_ids
    if attributes.key?(:attendee_ids) && !(attendee_ids - household_member_ids).empty?
      return render json: { error: "attendee_ids must be household members" }, status: :bad_request
    end

    Event.transaction do
      @event.update!(attributes.except(:attendee_ids))
      replace_attendees(attendee_ids) if attributes.key?(:attendee_ids)
    end
    render json: event_json(@event)
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: error.record.errors.full_messages.to_sentence }, status: :bad_request
  end

  def update_occurrence
    occurrence_start = parse_timestamp(params[:occurrence_start], "occurrence_start")
    unless CalendarService.new.occurrence?(@event, occurrence_start)
      return render json: { error: "occurrence_start is not an occurrence of this event" }, status: :bad_request
    end

    attributes = event_params
    forbidden = attributes.keys & %i[recurring recurrence_until attendee_ids all_day]
    return render json: { error: "#{forbidden.join(', ')} cannot be changed for one occurrence" }, status: :bad_request if forbidden.any?

    existing = @event.event_exceptions.find_by(original_start: occurrence_start)
    current_start = existing&.start_timestamp || occurrence_start
    current_end = existing&.end_timestamp || occurrence_start + (@event.end_timestamp - @event.start_timestamp)
    new_start = attributes.fetch(:start_timestamp, current_start)
    new_end = attributes.fetch(:end_timestamp, current_end)
    if new_end <= new_start
      return render json: { error: "end_timestamp must be after start_timestamp" }, status: :bad_request
    end

    exception = @event.event_exceptions.find_or_initialize_by(original_start: occurrence_start)
    exception.assign_attributes(attributes.merge(is_cancelled: false))
    exception.save!
    render json: occurrence_json(@event, occurrence_start, exception)
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: error.record.errors.full_messages.to_sentence }, status: :bad_request
  rescue ActionController::BadRequest => error
    render json: { error: error.message }, status: :bad_request
  end

  def calendar_range
    from = parse_timestamp(params[:from], "from")
    to = parse_timestamp(params[:to], "to")
    raise ActionController::BadRequest, "to must be after from" unless to >= from

    [from, to]
  end

  def parse_timestamp(value, field)
    raise ActionController::BadRequest, "#{field} is required" if value.blank?

    Time.zone.iso8601(value)
  rescue ArgumentError, TypeError
    raise ActionController::BadRequest, "#{field} must be an ISO 8601 timestamp"
  end

  def event_json(event)
    attributes = {
      event_id: event.respond_to?(:event_id) ? event.event_id : event.id,
      household_id: event.household_id,
      name: event.name,
      description: event.description,
      start_timestamp: event.start_timestamp.utc.iso8601,
      end_timestamp: event.end_timestamp.utc.iso8601,
      all_day: event.all_day,
      recurring: event.recurring,
      recurrence_until: event.recurrence_until&.iso8601,
      attendee_ids: event.attendee_ids,
      created_by: event.created_by
    }
    if event.respond_to?(:original_start)
      attributes[:original_start] = event.original_start.utc.iso8601
    end
    attributes
  end

  def occurrence_json(event, original_start, exception)
    event_json(event).merge(
      name: exception.name || event.name,
      description: exception.description || event.description,
      start_timestamp: (exception.start_timestamp || original_start).utc.iso8601,
      end_timestamp: (exception.end_timestamp || original_start + (event.end_timestamp - event.start_timestamp)).utc.iso8601,
      original_start: original_start.utc.iso8601
    )
  end

  def render_bad_request(error)
    render json: { error: error.message }, status: :bad_request
  end

  def render_not_found
    render json: { error: "resource not found" }, status: :not_found
  end
end
