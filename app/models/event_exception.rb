class EventException < ApplicationRecord
  self.primary_key = [:event_id, :original_start]

  belongs_to :event

  validates :name, presence: true, length: { maximum: 200 }, allow_nil: true
  validates :end_timestamp, comparison: { greater_than: :start_timestamp },
                            if: -> { start_timestamp.present? && end_timestamp.present? }
end
