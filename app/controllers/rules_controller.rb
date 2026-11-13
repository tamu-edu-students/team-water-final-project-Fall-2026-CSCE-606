class RulesController < ApplicationController
  before_action :require_login
  before_action :set_household
  before_action :check_membership
  before_action :set_rule, only: %i[show vote amend create_amendment history]
  before_action :require_approved_rule, only: %i[amend create_amendment]

  def index
    @approved_rules = @household.rules.active_agreements.order(approved_at: :desc)
    @open_proposals = @household.rules.proposed.includes(:created_by, :rule_votes).order(created_at: :desc)
    @past_proposals = @household.rules.where(status: %w[rejected archived]).order(updated_at: :desc)
  end

  def new
    @rule = @household.rules.build
  end

  def create
    @rule = @household.rules.build(rule_params)
    @rule.created_by = current_user

    if @rule.save
      redirect_to household_rules_path(@household), notice: "Rule proposal was successfully submitted."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @revisions = @rule.rule_revisions.order(version: :desc)
  end

  def vote
    decision = params[:decision]

    if @rule.status != "proposed"
      redirect_to household_rules_path(@household), alert: "Voting on this proposal is already closed."
    elsif @rule.voted_by?(current_user)
      redirect_to household_rules_path(@household), alert: "You have already voted on this proposal."
    elsif %w[approve reject].exclude?(decision)
      redirect_to household_rules_path(@household), alert: "Invalid vote option."
    else
      @rule.cast_vote!(current_user, decision)
      redirect_to household_rules_path(@household), notice: "Your vote has been recorded."
    end
  end

  def amend
    @parent_rule = @rule
    @rule = @household.rules.build(
      parent_rule: @parent_rule,
      title: "Amendment: #{@parent_rule.title}",
      category: @parent_rule.category,
      description: @parent_rule.description
    )
  end

  def create_amendment
    @parent_rule = @rule
    @rule = @household.rules.build(amendment_params)
    @rule.created_by = current_user
    @rule.parent_rule = @parent_rule
    @rule.title = "Amendment: #{@parent_rule.title}" if @rule.title.blank?
    @rule.category = @parent_rule.category

    if @rule.save
      redirect_to household_rules_path(@household), notice: "Amendment proposal was successfully submitted."
    else
      render :amend, status: :unprocessable_entity
    end
  end

  def history
    @revisions = @rule.rule_revisions.order(version: :desc)
  end

  private

  def set_household
    @household = Household.find(params[:household_id])
    session[:current_household_id] = @household.id if @household.persisted?
  end

  def check_membership
    unless @household.users.include?(current_user)
      redirect_to root_path, alert: "You are not a member of this household"
    end
  end

  def set_rule
    @rule = @household.rules.find(params[:id])
  end

  def require_approved_rule
    unless @rule.status == "approved"
      redirect_to household_rules_path(@household), alert: "Only approved rules can be amended."
    end
  end

  def rule_params
    params.require(:rule).permit(:title, :category, :description)
  end

  def amendment_params
    params.require(:rule).permit(:title, :description, :amendment_reason)
  end
end
