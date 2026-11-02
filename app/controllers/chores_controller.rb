class ChoresController < ApplicationController
  before_action :require_login
  before_action :set_household
  before_action :set_chore, only: %i[edit update destroy]
  before_action :authorize_chore_edit, only: %i[edit update destroy]

  def index
    @chores = @household.chores.includes(:assignees, :creator).order(:due_at, :title)
    @members = @household.users.order(:name, :id)
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
    redirect_to household_chores_path(@household), notice: "Chore created."
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
    params.require(:chore).permit(:title, :description, :due_at, :frequency)
  end

  def parsed_assignee_ids
    raw_ids = params.require(:chore).permit(assignee_ids: [])[:assignee_ids] || []
    raw_ids.map { |id| Integer(id) }.uniq
  rescue ArgumentError, TypeError
    []
  end
end
