class ChoreTemplatesController < ApplicationController
  before_action :require_login
  before_action :set_household

  def destroy
    template = @household.chore_templates.find_by(id: params[:id])
    return render file: Rails.public_path.join("404.html"), status: :not_found, layout: false unless template

    unless @household.admin?(current_user) || template.created_by_id == current_user.id
      return redirect_to household_chores_path(@household, anchor: "add-chore"),
                         alert: "Only the household admin or the person who saved it can remove this common chore."
    end

    template.destroy!
    redirect_to household_chores_path(@household, anchor: "add-chore"),
                notice: "Removed “#{template.title}” from common chores."
  end

  private

  def set_household
    @household = current_user.households.find(params[:household_id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end
end
