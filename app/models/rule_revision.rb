class RuleRevision < ApplicationRecord
  belongs_to :rule
  belongs_to :proposed_by, class_name: "User"

  validates :description, presence: true
  validates :version, numericality: { greater_than_or_equal_to: 1 }
end
