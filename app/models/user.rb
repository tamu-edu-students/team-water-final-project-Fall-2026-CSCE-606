class User < ApplicationRecord
  has_secure_password

  has_one :notification_preference, dependent: :destroy
  has_many :household_memberships, dependent: :destroy
  has_many :households, through: :household_memberships
  has_many :created_events, class_name: "Event", foreign_key: :created_by,
                            inverse_of: :creator, dependent: :restrict_with_error
  has_many :personal_events, foreign_key: :creator_id, inverse_of: :creator,
                             dependent: :destroy
  has_many :personal_event_attendees, dependent: :destroy
  has_many :invited_personal_events, through: :personal_event_attendees,
                                    source: :personal_event

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

  # Rule associations
  has_many :created_rules,
           class_name: "Rule",
           foreign_key: :created_by_id,
           inverse_of: :created_by,
           dependent: :destroy
  has_many :rule_votes, dependent: :destroy

  AVATAR_PRESETS = {
    "cat" => { label: "Kitten", emoji: "🐱", bg: "#fbf3ea" },
    "dog" => { label: "Puppy", emoji: "🐶", bg: "#f8f1e7" },
    "fox" => { label: "Fox", emoji: "🦊", bg: "#fdf2e9" },
    "panda" => { label: "Panda", emoji: "🐼", bg: "#eef4ed" },
    "koala" => { label: "Koala", emoji: "🐨", bg: "#eaf2f1" },
    "bunny" => { label: "Bunny", emoji: "🐰", bg: "#fdf2f4" },
    "bear" => { label: "Bear", emoji: "🐻", bg: "#f7efe5" },
    "frog" => { label: "Frog", emoji: "🐸", bg: "#e5f0e1" },
    "owl" => { label: "Owl", emoji: "🦉", bg: "#edf1f2" },
    "penguin" => { label: "Penguin", emoji: "🐧", bg: "#edf4f7" },
    "hamster" => { label: "Hamster", emoji: "🐹", bg: "#fcf4e8" },
    "lion" => { label: "Lion Cub", emoji: "🦁", bg: "#fdf6e6" }
  }.freeze

  def gravatar_url(size = 80)
    hash = Digest::SHA256.hexdigest(email.to_s.strip.downcase)
    "https://www.gravatar.com/avatar/#{hash}?d=identicon&s=#{size}"
  end

  def preset_avatar
    AVATAR_PRESETS[avatar_key]
  end

  def avatar_emoji
    preset_avatar&.dig(:emoji)
  end

  def avatar_bg
    preset_avatar&.dig(:bg) || "#e3ecdd"
  end

  def avatar_mode
    if avatar_key == "gravatar"
      :gravatar
    elsif AVATAR_PRESETS.key?(avatar_key)
      :preset
    else
      :initials
    end
  end

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
