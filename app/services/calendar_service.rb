class CalendarService
  Occurrence = Struct.new(:event_id, :original_start, :name, :description,
                          :start_timestamp, :end_timestamp, :all_day, :recurring,
                          :recurrence_until, :attendee_ids, :created_by, :household_id, :type,
                          keyword_init: true)
  ChoreOccurrence = Struct.new(:chore_id, :name, :description, :start_timestamp,
                               :end_timestamp, :household_id, :assignee_ids, :type,
                               keyword_init: true)
  CalendarItem = Struct.new(:id, :type, :name, :description, :start_timestamp,
                            :end_timestamp, :household_id, :assignee_ids, :attributes,
                            keyword_init: true)

  def events_for(household, from:, to:, user_id: nil)
    events = household.events
    if user_id.present?
      events = events.left_joins(:event_attendees)
                     .where("event_attendees.user_id = ? OR NOT EXISTS (SELECT 1 FROM event_attendees ea WHERE ea.event_id = events.event_id)",
                            user_id)
                     .distinct
    end
    events = events.where(
      <<~SQL.squish,
        (events.start_timestamp <= ? AND (
          (events.recurring = 'NONE' AND events.end_timestamp >= ?)
          OR (events.recurring <> 'NONE' AND (events.recurrence_until IS NULL OR events.recurrence_until >= ?))
        ))
        OR EXISTS (
          SELECT 1 FROM event_exceptions ex
          WHERE ex.event_id = events.event_id
            AND ex.is_cancelled = FALSE
            AND COALESCE(ex.start_timestamp, ex.original_start) <= ?
            AND COALESCE(
              ex.end_timestamp,
              ex.original_start + (events.end_timestamp - events.start_timestamp)
            ) >= ?
        )
      SQL
      to, from, from.to_date, to, from
    )
                   .includes(:event_attendees, :event_exceptions)

    events.flat_map { |event| expand(event, from, to) }
          .sort_by { |occurrence| [occurrence.start_timestamp, occurrence.event_id] }
  end

  def calendar_items_for(household, from:, to:, user_id: nil, additional_items: [])
    events = events_for(household, from:, to:, user_id:)
    chores = chores_for(household, from:, to:, user_id:)
    additional = additional_items.filter_map do |item|
      normalize_additional_item(item, household:, from:, to:)
    end

    (events + chores + additional)
      .sort_by { |item| [item.start_timestamp, item.type == :event ? 0 : 1, item.name] }
  end

  def chores_for(household, from:, to:, user_id: nil)
    chores = household.chores.where.not(due_at: nil)
    chores = chores.joins(:chore_assignments).where(chore_assignments: { user_id: }) if user_id.present?
    chores = chores.where("chores.due_at <= ?", to).includes(:chore_assignments)
    chores = chores.includes(:assignees)

    chores.flat_map { |chore| expand_chore(chore, from, to) }
  end

  def occurrence?(event, original_start)
    return event.start_timestamp == original_start if event.recurring == "NONE"

    recurrence_times(event, original_start, original_start).include?(original_start)
  end

  private

  def normalize_additional_item(item, household:, from:, to:)
    attributes = item.to_h.symbolize_keys
    type = attributes.delete(:type).to_s
    name = attributes.delete(:name)
    start_timestamp = attributes.delete(:start_timestamp) || attributes.delete(:due_at)
    raise ArgumentError, "additional calendar items require a type, name, and timestamp" if type.blank? || name.blank? || start_timestamp.blank?

    start_timestamp = start_timestamp.in_time_zone if start_timestamp.respond_to?(:in_time_zone)
    end_timestamp = attributes.delete(:end_timestamp)
    end_timestamp = end_timestamp.in_time_zone if end_timestamp.respond_to?(:in_time_zone)
    end_timestamp ||= start_timestamp
    household_id = attributes.delete(:household_id) || household.id
    return unless household_id.to_i == household.id && end_timestamp >= from && start_timestamp <= to

    CalendarItem.new(
      id: attributes.delete(:id),
      type: type.to_sym,
      name:,
      description: attributes.delete(:description),
      start_timestamp:,
      end_timestamp:,
      household_id:,
      assignee_ids: attributes.delete(:assignee_ids) || [],
      attributes:
    )
  rescue NoMethodError
    raise ArgumentError, "additional calendar items must provide hash-like calendar attributes"
  end

  def expand(event, from, to)
    return [] if event.recurring == "NONE" && (event.end_timestamp < from || event.start_timestamp > to)

    duration = event.end_timestamp - event.start_timestamp
    exceptions = event.event_exceptions.index_by(&:original_start)
    timestamps = if event.recurring == "NONE"
                   [event.start_timestamp]
                 else
                   recurrence_times(event, from - duration, to)
                 end

    exceptions.each_value do |exception|
      next if exception.is_cancelled || exception.start_timestamp.nil?

      exception_end = exception.end_timestamp || exception.start_timestamp + duration
      if exception_end >= from && exception.start_timestamp <= to &&
         occurrence?(event, exception.original_start)
        timestamps << exception.original_start
      end
    end

    timestamps.uniq.filter_map do |original_start|
      exception = exceptions[original_start]
      next if exception&.is_cancelled

      start_time = exception&.start_timestamp || original_start
      end_time = exception&.end_timestamp || original_start + duration
      next if end_time < from || start_time > to

      Occurrence.new(
        event_id: event.id,
        original_start:,
        name: exception&.name || event.name,
        description: exception&.description || event.description,
        start_timestamp: start_time,
        end_timestamp: end_time,
        all_day: event.all_day,
        recurring: event.recurring,
        recurrence_until: event.recurrence_until,
        attendee_ids: event.event_attendees.map(&:user_id),
        created_by: event.created_by,
        household_id: event.household_id,
        type: :event
      )
    end
  end

  def expand_chore(chore, from, to)
    return [] if chore.due_at > to

    timestamps = if chore.frequency == "NONE"
                   chore.due_at.between?(from, to) ? [chore.due_at] : []
                 else
                   recurring_chore_times(chore, from, to)
                 end

    timestamps.map do |timestamp|
      ChoreOccurrence.new(
        chore_id: chore.id,
        name: chore.title,
        description: chore.description,
        start_timestamp: timestamp,
        end_timestamp: timestamp,
        household_id: chore.household_id,
        assignee_ids: chore.chore_assignments.map(&:user_id),
        type: :chore
      )
    end
  end

  def recurring_chore_times(chore, from, to)
    index = recurrence_index_for_frequency(chore.frequency, chore.due_at, from)
    timestamp = chore_time_at_index(chore, index)
    timestamp = chore_time_at_index(chore, index + 1) while timestamp < from

    timestamps = []
    while timestamp <= to
      timestamps << timestamp
      index += 1
      timestamp = chore_time_at_index(chore, index)
    end
    timestamps
  end

  def recurrence_index_for_frequency(frequency, start_time, time)
    case frequency
    when "DAILY"
      [(time.to_date - start_time.to_date).to_i, 0].max
    when "WEEKLY"
      [((time.to_date - start_time.to_date).to_i / 7), 0].max
    when "MONTHLY"
      [((time.year - start_time.year) * 12 + time.month - start_time.month), 0].max
    else
      0
    end
  end

  def chore_time_at_index(chore, index)
    case chore.frequency
    when "DAILY" then chore.due_at + index.days
    when "WEEKLY" then chore.due_at + (index * 7).days
    when "MONTHLY" then chore.due_at.advance(months: index)
    else chore.due_at
    end
  end

  def recurrence_times(event, from, to)
    return [] if to < event.start_timestamp || recurrence_expired?(event, from)

    duration = event.end_timestamp - event.start_timestamp
    first_relevant = [from, event.start_timestamp].max
    target_start = first_relevant - duration
    index = recurrence_index(event, target_start)
    time = occurrence_at_index(event, index)
    while index.positive? && occurrence_at_index(event, index - 1) >= target_start
      index -= 1
      time = occurrence_at_index(event, index)
    end
    time = occurrence_at_index(event, index + 1) while time < target_start

    occurrences = []
    while time <= to && within_recurrence_end?(event, time)
      occurrences << time if time >= target_start
      index += 1
      time = occurrence_at_index(event, index)
    end
    occurrences
  end

  def recurrence_index(event, time)
    case event.recurring
    when "DAILY"
      [(time.to_date - event.start_timestamp.to_date).to_i, 0].max
    when "WEEKLY"
      [((time.to_date - event.start_timestamp.to_date).to_i / 7), 0].max
    when "MONTHLY"
      [((time.year - event.start_timestamp.year) * 12 + time.month - event.start_timestamp.month), 0].max
    else
      0
    end
  end

  def occurrence_at_index(event, index)
    case event.recurring
    when "DAILY" then event.start_timestamp + index.days
    when "WEEKLY" then event.start_timestamp + (index * 7).days
    when "MONTHLY" then event.start_timestamp.advance(months: index)
    else event.start_timestamp
    end
  end

  def within_recurrence_end?(event, time)
    event.recurrence_until.nil? || time.to_date <= event.recurrence_until
  end

  def recurrence_expired?(event, time)
    event.recurrence_until.present? && time.to_date > event.recurrence_until
  end
end