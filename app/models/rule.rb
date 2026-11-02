class Rule < ApplicationRecord
  CATEGORIES = [
    "General",
    "Noise & Quiet Hours",
    "Guests & Visitors",
    "Cleanliness & Chores",
    "Shared Spaces",
    "Food & Kitchen"
  ].freeze

  STATUSES = %w[proposed approved rejected archived].freeze

  belongs_to :household
  belongs_to :created_by, class_name: "User"
  belongs_to :parent_rule, class_name: "Rule", optional: true

  has_many :amendments,
           class_name: "Rule",
           foreign_key: :parent_rule_id,
           inverse_of: :parent_rule,
           dependent: :destroy

  has_many :rule_votes, dependent: :destroy
  has_many :rule_revisions, -> { order(version: :asc) }, inverse_of: :rule, dependent: :destroy

  validates :title, presence: true, length: { maximum: 120 }
  validates :description, presence: true
  validates :category, presence: true
  validates :status, inclusion: { in: STATUSES }

  validate :parent_rule_must_be_valid, if: -> { parent_rule_id.present? }

  scope :proposed, -> { where(status: "proposed") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :active_agreements, -> { where(status: "approved", parent_rule_id: nil) }

  after_create :record_creator_vote

  def active_rule_votes
    rule_votes.where(user_id: household.household_memberships.select(:user_id))
  end

  def approve_votes_count
    active_rule_votes.where(decision: "approve").count
  end

  def reject_votes_count
    active_rule_votes.where(decision: "reject").count
  end

  def total_eligible_voters
    household.users.count
  end

  def majority_threshold
    (total_eligible_voters / 2) + 1
  end

  def max_rejections_allowed
    total_eligible_voters - majority_threshold
  end

  def voted_by?(user)
    rule_votes.exists?(user: user)
  end

  def vote_by(user)
    rule_votes.find_by(user: user)
  end

  def cast_vote!(user, decision)
    return false unless status == "proposed"

    vote = rule_votes.find_or_initialize_by(user: user)
    vote.decision = decision
    return false unless vote.save

    evaluate_status!
    true
  end

  def evaluate_status!
    return unless status == "proposed"

    if approve_votes_count >= majority_threshold
      approve_proposal!
    elsif reject_votes_count > max_rejections_allowed
      update!(status: "rejected")
    end
  end

  def apply_amendment!(amendment_rule)
    next_version = (rule_revisions.maximum(:version) || 1) + 1
    update!(description: amendment_rule.description)
    rule_revisions.create!(
      proposed_by: amendment_rule.created_by,
      description: amendment_rule.description,
      reason: amendment_rule.amendment_reason,
      version: next_version,
      approved_at: Time.current
    )
  end

  private

  def parent_rule_must_be_valid
    return unless parent_rule

    if parent_rule.household_id != household_id
      errors.add(:parent_rule, "must belong to the same household")
    end
    if parent_rule.parent_rule_id.present?
      errors.add(:parent_rule, "cannot be an amendment itself")
    end
    if parent_rule.status != "approved"
      errors.add(:parent_rule, "must be an approved rule to be amended")
    end
  end

  def record_creator_vote
    rule_votes.create!(user: created_by, decision: "approve")
    evaluate_status!
  end

  def approve_proposal!
    transaction do
      if parent_rule.present?
        parent_rule.apply_amendment!(self)
        update!(status: "approved", approved_at: Time.current)
      else
        update!(status: "approved", approved_at: Time.current)
        rule_revisions.create!(
          proposed_by: created_by,
          description: description,
          reason: "Initial proposed rule approved",
          version: 1,
          approved_at: Time.current
        )
      end
    end
  end
end
