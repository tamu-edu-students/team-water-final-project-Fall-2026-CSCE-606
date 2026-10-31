class Household < ApplicationRecord
  belongs_to :creator, class_name: "User"

  has_many :household_memberships, dependent: :destroy
  has_many :users, through: :household_memberships
  has_many :events, dependent: :destroy
  has_many :chores, dependent: :destroy

  has_secure_token :invite_code

  validates :name, presence: true
  validates :invite_code, uniqueness: true, allow_nil: true
  validates :invite_code, uniqueness: true, allow_nil: true

  def admin?(user)
    user.present? && (creator_id == user.id || household_memberships.exists?(user_id: user.id, role: "admin"))
  end
end
