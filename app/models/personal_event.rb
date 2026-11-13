class PersonalEvent < ApplicationRecord
  VISIBILITIES = %w[private shared].freeze

  belongs_to :creator, class_name: "User", inverse_of: :personal_events
  belongs_to :household, optional: true
  has_many :personal_event_attendees, dependent: :destroy
  has_many :attendees, through: :personal_event_attendees, source: :user

  validates :title, presence: true, length: { maximum: 200 }
  validates :event_date, presence: true
  validates :visibility, inclusion: { in: VISIBILITIES }
  validate :household_matches_visibility

  scope :visible_to, ->(user) {
    left_joins(:personal_event_attendees, household: :household_memberships)
      .where("personal_events.creator_id = :user_id OR " \
             "(personal_events.visibility = 'shared' AND personal_event_attendees.user_id = :user_id " \
             "AND household_memberships.user_id = :user_id)",
             user_id: user.id)
      .distinct
  }

  def attendee_ids
    personal_event_attendees.pluck(:user_id)
  end

  private

  def household_matches_visibility
    if visibility == "private" && household_id.present?
      errors.add(:household, "must be blank for private events")
    elsif visibility == "shared" && household_id.blank?
      errors.add(:household, "must be selected for shared events")
    end
  end
end
