class PersonalEventsController < ApplicationController
  before_action :require_login
  before_action :set_households, only: %i[new create edit update]
  before_action :set_personal_event, only: %i[show edit update destroy]
  before_action :require_creator, only: %i[edit update destroy]

  def new
    @personal_event = current_user.personal_events.build(event_date: calendar_date || Date.current)
    @selected_attendee_ids = []
  end

  def create
    @personal_event = current_user.personal_events.build
    assign_event_attributes
    return render :new, status: :unprocessable_entity unless valid_sharing_selection?

    PersonalEvent.transaction do
      @personal_event.save!
      @selected_attendee_ids.each do |user_id|
        @personal_event.personal_event_attendees.create!(user_id:)
      end
    end
    redirect_to personal_event_path(@personal_event), notice: "Personal event created."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def show
  end

  def edit
    @selected_attendee_ids = @personal_event.attendee_ids
  end

  def update
    assign_event_attributes
    return render :edit, status: :unprocessable_entity unless valid_sharing_selection?

    PersonalEvent.transaction do
      @personal_event.update!(@event_attributes)
      @personal_event.personal_event_attendees.destroy_all
      @selected_attendee_ids.each do |user_id|
        @personal_event.personal_event_attendees.create!(user_id:)
      end
    end
    redirect_to personal_event_path(@personal_event), notice: "Personal event updated."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @personal_event.destroy!
    redirect_to calendar_path, notice: "Personal event deleted."
  end

  private

  def set_households
    @households = current_user.households.includes(:users).order(:name, :id)
    @shareable_households = @households.select do |household|
      household.users.any? { |member| member.id != current_user.id }
    end
  end

  def set_personal_event
    @personal_event = PersonalEvent.visible_to(current_user).find(params[:id])
  end

  def require_creator
    return if @personal_event.creator_id == current_user.id

    redirect_to personal_event_path(@personal_event), alert: "Only the creator can change this event."
  end

  def assign_event_attributes
    @event_attributes = personal_event_params
    @selected_attendee_ids = parse_attendee_ids(@event_attributes.delete(:attendee_ids))
    @personal_event.assign_attributes(@event_attributes)
  end

  def personal_event_params
    params.require(:personal_event).permit(:title, :description, :event_date, :visibility, :household_id,
                                          attendee_ids: [])
  end

  def parse_attendee_ids(raw_ids)
    Array(raw_ids).reject(&:blank?).map { |id| Integer(id) }.uniq
  rescue ArgumentError, TypeError
    @personal_event.errors.add(:attendees, "must be valid household members")
    []
  end

  def valid_sharing_selection?
    if @personal_event.visibility == "private"
      @personal_event.household = nil
      @event_attributes[:household_id] = nil
      @selected_attendee_ids = []
      return true
    end

    household = @households.find { |candidate| candidate.id == @personal_event.household_id }
    unless household
      @personal_event.errors.add(:household, "must be one of your households")
      return false
    end

    unless @selected_attendee_ids.any?
      @personal_event.errors.add(:attendees, "must include at least one household member")
      return false
    end

    if (@selected_attendee_ids - household.user_ids).any? || @selected_attendee_ids.include?(current_user.id)
      @personal_event.errors.add(:attendees, "must be other members of the selected household")
      return false
    end

    true
  end

  def calendar_date
    return if params[:date].blank?

    Date.iso8601(params[:date])
  rescue Date::Error
    raise ActionController::BadRequest, "date must be an ISO 8601 date"
  end
end
