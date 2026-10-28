class Expense < ApplicationRecord
  belongs_to :household
  belongs_to :created_by, class_name: "User", foreign_key: "created_by_id"
  has_many :expense_participants, dependent: :destroy
  has_many :participants, through: :expense_participants, source: :user

  validates :title, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :expense_date, presence: true

  # For precise decimal arithmetic as mentioned in risk mitigation [1]
  def split_equally
    participant_count = household.users.count
    return if participant_count == 0
    
    # Calculate individual amount with proper rounding
    individual_amount = (amount / participant_count).round(2)
    
    # Handle rounding cremainder on the last participant
    household.users.each_with_index do |user, index|
      if index == participant_count - 1
        # Last person gets the remainder to ensure exact total
        already_allocated = individual_amount * (participant_count - 1)
        final_amount = (amount - already_allocated).round(2)
      else
        final_amount = individual_amount
      end
      
      expense_participants.create!(
        user: user,
        amount_owed: final_amount,
        payment_status: 'pending'
      )
    end
  end

  def split_custom(splits)
    # splits = { user_id => percentage }
    splits.each do |user_id, percentage|
      amount_owed = (amount * percentage / 100.0).round(2)
      expense_participants.create!(
        user_id: user_id,
        amount_owed: amount_owed,
        payment_status: "pending"
      )
    end
  end
end
