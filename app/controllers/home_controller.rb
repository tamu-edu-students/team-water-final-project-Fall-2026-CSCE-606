class HomeController < ApplicationController
  before_action :require_login

  def index
    @households = current_user.households.order(:name, :id)
  end

  def calendar
    @households = current_user.households.order(:name, :id)
    load_calendar
  end

  private

  def load_calendar
    @calendar_month = requested_calendar_month
    @calendar_start = @calendar_month.beginning_of_week(:sunday)
    @calendar_end = @calendar_month.end_of_month.end_of_week(:sunday)
    from = @calendar_start.in_time_zone.beginning_of_day
    to = @calendar_end.in_time_zone.end_of_day
    household_names = @households.index_by(&:id).transform_values(&:name)
    calendar_service = CalendarService.new
    events = @households.flat_map do |household|
      calendar_service.calendar_items_for(household, from:, to:, user_id: current_user.id)
    end
    events_by_date = events.group_by { |event| event.start_timestamp.to_date }

    @calendar_days = (@calendar_start..@calendar_end).map do |date|
      {
        date: date,
        events: events_by_date.fetch(date, [])
                             .map { |event| [ event, household_names.fetch(event.household_id) ] }
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
