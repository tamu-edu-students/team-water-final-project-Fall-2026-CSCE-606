class PersonalEventAttendee < ApplicationRecord
  belongs_to :personal_event
  belongs_to :user

  validates :user_id, uniqueness: { scope: :personal_event_id }
end
