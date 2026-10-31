class User < ApplicationRecord
  has_secure_password

  has_many :household_memberships, dependent: :destroy
  has_many :households, through: :household_memberships
  has_many :created_events, class_name: "Event", foreign_key: :created_by,
                            inverse_of: :creator, dependent: :restrict_with_error

  has_many :created_households,
           class_name: "Household",
           foreign_key: :creator_id,
           inverse_of: :creator,
           dependent: :restrict_with_error

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
