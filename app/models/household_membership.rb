class HouseholdMembership < ApplicationRecord
  belongs_to :user
  belongs_to :household

  validates :role, inclusion: { in: %w[admin member] }
  validates :user_id, uniqueness: { scope: :household_id }

  after_destroy :cleanup_pending_votes_and_reevaluate_rules

  private

  def cleanup_pending_votes_and_reevaluate_rules
    return if household.blank? || household.destroyed?

    RuleVote.joins(:rule)
            .where(user_id: user_id, rules: { household_id: household_id, status: "proposed" })
            .destroy_all

    household.rules.proposed.find_each(&:evaluate_status!)
  end
end
