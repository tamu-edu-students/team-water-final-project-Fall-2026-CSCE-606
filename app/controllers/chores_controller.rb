class ChoresController < ApplicationController
  PENDING_LIMIT = 20
  UPCOMING_DAYS = 14
  UPCOMING_LIMIT = 10

  before_action :require_login
  before_action :set_household
  before_action :set_chore, only: %i[edit update destroy]
  before_action :authorize_chore_edit, only: %i[edit update destroy]

  def index
    @chores = @household.chores.includes(:assignees, :creator).order(:due_at, :title)
    @category_counts = @chores.map(&:category).tally
    @active_category = Chore::CATEGORIES.include?(params[:category]) ? params[:category] : nil
    @members = @household.users.order(:name, :id)
    @saved_templates = @household.chore_templates.includes(:creator).order(:title)
    @templates = Chore::TEMPLATES + @saved_templates.map(&:to_template)
    @new_chore = build_new_chore
    @existing_titles = @chores.map { |chore| chore.title.downcase }.to_set
    load_schedule
  end

  def edit
    @members = @household.users.order(:name, :id)
  end

  def create
    assignee_ids = parsed_assignee_ids
    unless assignee_ids.any? && (assignee_ids - @household.user_ids).empty?
      return redirect_to household_chores_path(@household),
                         alert: "Choose one or more members of this household."
    end

    chore = @household.chores.new(chore_params)
    chore.creator = current_user
    Chore.transaction do
      chore.save!
      assignee_ids.each { |user_id| chore.chore_assignments.create!(user_id:) }
    end
    HouseholdNotificationDispatcher.chore_created(
      chore: chore,
      actor: current_user
    )
    saved = save_as_template(chore)
    redirect_to household_chores_path(@household),
                notice: saved ? "Chore created and saved to your common chores." : "Chore created."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to household_chores_path(@household),
                alert: error.record.errors.full_messages.to_sentence
  end

  def update
    assignee_ids = parsed_assignee_ids
    unless assignee_ids.any? && (assignee_ids - @household.user_ids).empty?
      return redirect_to edit_household_chore_path(@household, @chore),
                         alert: "Choose one or more members of this household."
    end

    Chore.transaction do
      @chore.update!(chore_params)
      @chore.chore_assignments.delete_all
      assignee_ids.each { |user_id| @chore.chore_assignments.create!(user_id:) }
    end
    redirect_to household_chores_path(@household), notice: "Chore updated."
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  rescue ActiveRecord::RecordInvalid => error
    redirect_to edit_household_chore_path(@household, @chore),
                alert: error.record.errors.full_messages.to_sentence
  end

  def destroy
    @chore.destroy!
    redirect_to household_chores_path(@household), notice: "Chore deleted."
  end

  private

  def set_household
    @household = current_user.households.find(params[:household_id])
    session[:current_household_id] = @household.id
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def set_chore
    @chore = @household.chores.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def authorize_chore_edit
    return if @household.admin?(current_user) || @chore.created_by_id == current_user.id

    redirect_to household_chores_path(@household),
                alert: authorization_message
  end

  def authorization_message
    action_name == "destroy" ?
      "Only the household admin or chore creator can delete this chore." :
      "Only the household admin or chore creator can edit this chore."
  end

  def chore_params
    params.require(:chore).permit(:title, :description, :due_at, :frequency, :category)
  end

  def parsed_assignee_ids
    raw_ids = params.require(:chore).permit(assignee_ids: [])[:assignee_ids] || []
    raw_ids.map { |id| Integer(id) }.uniq
  rescue ArgumentError, TypeError
    []
  end

  def build_new_chore
    template = find_template(params[:template])
    attributes = { due_at: calendar_due_at }
    attributes.merge!(template.slice(:title, :description, :category, :frequency)) if template
    @active_template = template&.dig(:key)
    @household.chores.build(attributes)
  end

  def find_template(key)
    return if key.blank?

    Chore.template(key) || @saved_templates.find { |saved| saved.id.to_s == ChoreTemplate.id_from_key(key) }&.to_template
  end

  # Saves a custom chore as a household common chore when the user asked for it.
  # Skips titles that already exist as a built-in or saved common chore.
  def save_as_template(chore)
    return false unless params[:save_as_template] == "1"
    return false if Chore::TEMPLATES.any? { |template| template[:title].casecmp?(chore.title.squish) }

    template = @household.chore_templates.new(
      chore.slice(:title, :description, :category, :frequency).merge(creator: current_user)
    )
    template.save
  end

  # Pending: chores due today plus one-off chores whose due date has passed.
  # Upcoming: each chore's next date from tomorrow through the next two weeks.
  def load_schedule
    now = Time.current
    chores_by_id = @chores.index_by(&:id)
    calendar = CalendarService.new
    overdue = @chores.select { |chore| chore.due_status(now) == :overdue }
                     .map { |chore| { chore: chore, at: chore.due_at, overdue: true } }
    today = calendar.chores_for(@household, from: now.beginning_of_day, to: now.end_of_day)
                    .map { |item| { chore: chores_by_id[item.chore_id], at: item.start_timestamp, overdue: false } }
    @pending = (overdue + today).select { |item| item[:chore] }.sort_by { |item| item[:at] }.first(PENDING_LIMIT)

    # One entry per chore at its next date, so daily chores don't crowd out everything else.
    upcoming = calendar.chores_for(@household, from: now.tomorrow.beginning_of_day,
                                               to: (now + UPCOMING_DAYS.days).end_of_day)
                       .group_by(&:chore_id)
                       .filter_map do |chore_id, items|
      chore = chores_by_id[chore_id]
      { chore: chore, at: items.min_by(&:start_timestamp).start_timestamp } if chore
    end
    upcoming.sort_by! { |item| [ item[:at], item[:chore].title ] }
    @upcoming_total = upcoming.size
    @upcoming_by_day = upcoming.first(UPCOMING_LIMIT).group_by { |item| item[:at].to_date }
    @upcoming_until = (now + UPCOMING_DAYS.days).to_date
  end

  def calendar_due_at
    return if params[:due_on].blank?

    Date.iso8601(params[:due_on]).in_time_zone.beginning_of_day
  rescue Date::Error
    raise ActionController::BadRequest, "due_on must be an ISO 8601 date"
  end
end
