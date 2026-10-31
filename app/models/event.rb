class Event < ApplicationRecord
  RECURRENCES = %w[NONE DAILY WEEKLY MONTHLY].freeze

  belongs_to :household
  belongs_to :creator, class_name: "User", foreign_key: :created_by, inverse_of: :created_events
  has_many :event_attendees, dependent: :delete_all
  has_many :attendees, through: :event_attendees, source: :user
  has_many :event_exceptions, dependent: :delete_all

  validates :name, presence: true, length: { maximum: 200 }
  validates :recurring, inclusion: { in: RECURRENCES }
  validates :start_timestamp, :end_timestamp, presence: true
  validates :end_timestamp, comparison: { greater_than: :start_timestamp },
                            if: -> { start_timestamp.present? && end_timestamp.present? }
  validates :recurrence_until, absence: true, if: -> { recurring == "NONE" }
  validate :attendees_belong_to_household

  def attendee_ids
    event_attendees.pluck(:user_id)
  end

  private

  def attendees_belong_to_household
    return if attendees.empty?
    return if attendees.where.not(id: household.user_ids).none?

    errors.add(:attendees, "must be members of the household")
  end
end
