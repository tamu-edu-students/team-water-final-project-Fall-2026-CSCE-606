class HomeController < ApplicationController
  before_action :require_login

  def index
    @households = current_user.households.order(:name, :id)
  end

  def calendar
    @households = current_user.households.order(:name, :id)
    @calendar_view = params[:view] == "household" ? "household" : "personal"
    @selected_household = selected_calendar_household
    @calendar_households = @selected_household ? [ @selected_household ] : @households
    @calendar_params = {
      view: @calendar_view,
      household_id: @selected_household&.id || "all"
    }
    load_calendar
  end

  private

  def selected_calendar_household
    return if params[:household_id].blank? || params[:household_id] == "all"

    @households.find(params[:household_id])
  end

  def load_calendar
    @calendar_month = requested_calendar_month
    @calendar_start = @calendar_month.beginning_of_week(:sunday)
    @calendar_end = @calendar_month.end_of_month.end_of_week(:sunday)
    from = @calendar_start.in_time_zone.beginning_of_day
    to = @calendar_end.in_time_zone.end_of_day
    household_names = @households.index_by(&:id).transform_values(&:name)
    calendar_service = CalendarService.new
    calendar_user_id = @calendar_view == "personal" ? current_user.id : nil
    events = @calendar_households.flat_map do |household|
      calendar_service.calendar_items_for(household, from:, to:, user_id: calendar_user_id)
    end
    if @calendar_view == "personal"
      personal_events = calendar_service.personal_events_for(current_user, from:, to:)
      events.concat(personal_events.select do |event|
        @selected_household.nil? || event.household_id.nil? || event.household_id == @selected_household.id
      end)
    end
    events_by_date = events.group_by { |event| event.start_timestamp.to_date }

    @calendar_days = (@calendar_start..@calendar_end).map do |date|
      {
        date: date,
        events: events_by_date.fetch(date, [])
                             .map { |event| [ event, household_names.fetch(event.household_id, "Personal") ] }
      }
    end
  end

  def requested_calendar_month
    return Date.current.beginning_of_month if params[:month].blank?

    Date.strptime(params[:month], "%Y-%m").beginning_of_month
  rescue Date::Error
    Date.current.beginning_of_month
  end
end
