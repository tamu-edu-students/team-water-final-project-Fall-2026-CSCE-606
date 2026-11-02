class RuleVote < ApplicationRecord
  DECISIONS = %w[approve reject].freeze

  belongs_to :rule
  belongs_to :user

  validates :decision, inclusion: { in: DECISIONS }
  validates :user_id, uniqueness: { scope: :rule_id, message: "has already voted on this rule" }

  validate :user_must_be_household_member

  private

  def user_must_be_household_member
    return unless rule && user

    unless rule.household.users.exists?(id: user.id)
      errors.add(:user, "must be a member of this household")
    end
  end
end
