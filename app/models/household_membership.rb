class HouseholdMembership < ApplicationRecord
  belongs_to :user
  belongs_to :household

  validates :role, inclusion: { in: %w[admin member] }
  validates :user_id, uniqueness: { scope: :household_id }
end
