class EventAttendee < ApplicationRecord
  self.primary_key = [:event_id, :user_id]

  belongs_to :event
  belongs_to :user
end
