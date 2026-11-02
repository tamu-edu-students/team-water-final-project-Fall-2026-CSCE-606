class Chore < ApplicationRecord
  FREQUENCIES = %w[NONE DAILY WEEKLY MONTHLY].freeze

  belongs_to :household
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id
  has_many :chore_assignments, dependent: :delete_all
  has_many :assignees, through: :chore_assignments, source: :user

  validates :title, presence: true, length: { maximum: 200 }
  validates :frequency, inclusion: { in: FREQUENCIES }
end
