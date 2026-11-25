# A custom chore a household saved so it appears alongside the built-in
# common chores (Chore::TEMPLATES) on the chores page.
class ChoreTemplate < ApplicationRecord
  KEY_PREFIX = "saved-".freeze

  belongs_to :household
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id

  normalizes :title, with: ->(title) { title.to_s.squish }

  validates :title, presence: true, length: { maximum: 200 },
                    uniqueness: { scope: :household_id, case_sensitive: false }
  validates :category, inclusion: { in: Chore::CATEGORIES }
  validates :frequency, inclusion: { in: Chore::FREQUENCIES }

  def self.key_for(id) = "#{KEY_PREFIX}#{id}"

  def self.id_from_key(key)
    key.to_s.delete_prefix(KEY_PREFIX) if key.to_s.start_with?(KEY_PREFIX)
  end

  def to_template
    { key: self.class.key_for(id), title:, description:, category:, frequency:, saved: true, record: self }
  end
end
