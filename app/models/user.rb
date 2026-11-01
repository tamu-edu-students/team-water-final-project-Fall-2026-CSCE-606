class User < ApplicationRecord
  has_secure_password

  has_many :household_memberships, dependent: :destroy
  has_many :households, through: :household_memberships

  has_many :created_households,
           class_name: "Household",
           foreign_key: :creator_id,
           inverse_of: :creator,
           dependent: :restrict_with_error

  # Expense associations
  has_many :created_expenses,
           class_name: "Expense",
           foreign_key: :created_by_id,
           dependent: :nullify
  has_many :expense_participants, dependent: :destroy
  has_many :participated_expenses, through: :expense_participants, source: :expense

  before_validation :normalize_email

  validates :name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  private

  def normalize_email
    self.email = email.strip.downcase if email.present?
  end
end
