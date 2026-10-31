class ExpenseParticipant < ApplicationRecord
  belongs_to :expense
  belongs_to :user

  validates :amount_owed, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :payment_status, inclusion: { in: %w[pending paid] }

  scope :pending, -> { where(payment_status: "pending") }
  scope :paid, -> { where(payment_status: "paid") }

  def mark_as_paid!
    update!(payment_status: "paid", paid_at: Time.current)
  end
end
