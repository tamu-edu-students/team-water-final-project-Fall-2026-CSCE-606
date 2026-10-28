class Expense < ApplicationRecord
  belongs_to :household
  belongs_to :created_by, class_name: "User", foreign_key: "created_by_id"
  has_many :expense_participants, dependent: :destroy
  has_many :participants, through: :expense_participants, source: :user

  validates :title, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :expense_date, presence: true

  PERCENTAGE_TOLERANCE = BigDecimal("0.01")

  # member_ids: optional list of user ids; defaults to the whole household.
  # Always scoped to household members, so outside ids are ignored.
  def split_equally(member_ids = nil)
    users = split_members(member_ids).to_a
    return fail_split("Select at least one member to split with") if users.empty?

    base, extra = amount_in_cents.divmod(users.size)

    # Spread leftover cents one each across the first participants
    # instead of dumping the whole remainder on the last person.
    shares = users.each_with_index.map { |user, i| [ user, base + (i < extra ? 1 : 0) ] }
    create_participants!(shares)
  end

  # splits = { user_id => percentage }
  def split_custom(splits, member_ids = nil)
    users = split_members(member_ids).index_by { |u| u.id.to_s }
    percentages = splits.to_h.transform_keys(&:to_s)
                        .slice(*users.keys)
                        .transform_values { |p| p.to_s.to_d }

    return fail_split("Select at least one member to split with") if percentages.empty?

    total = percentages.values.sum
    if (total - 100).abs > PERCENTAGE_TOLERANCE
      return fail_split("Custom split percentages must equal 100% (currently #{total.to_f}%)")
    end

    cents = amount_in_cents
    shares = percentages.map { |id, pct| [ users[id], (cents * pct / 100).round.to_i ] }

    # Last participant absorbs any rounding difference so the total is exact
    allocated = shares[0..-2].sum { |_, c| c }
    shares[-1][1] = cents - allocated

    create_participants!(shares)
  end

  private

  def split_members(member_ids)
    scope = household.users
    member_ids.nil? ? scope : scope.where(id: member_ids)
  end

  def amount_in_cents
    (amount * 100).round.to_i
  end

  def create_participants!(shares)
    transaction do
      shares.each do |user, cents|
        expense_participants.create!(
          user: user,
          amount_owed: BigDecimal(cents) / 100,
          payment_status: "pending"
        )
      end
    end
    true
  end

  def fail_split(message)
    errors.add(:base, message)
    false
  end
end
