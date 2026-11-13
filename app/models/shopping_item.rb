class ShoppingItem < ApplicationRecord
  CATEGORIES = %w[Groceries Cleaning Toiletries Household Other].freeze

  belongs_to :household
  belongs_to :inventory_item, optional: true
  belongs_to :added_by, class_name: "User"
  belongs_to :purchased_by, class_name: "User", optional: true

  enum :priority, { low: 0, normal: 1, high: 2 }, validate: true

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, length: { maximum: 100 }
  validates :name, uniqueness: { scope: :household_id, case_sensitive: false,
                                 conditions: -> { where(purchased_at: nil) },
                                 message: "is already on the shopping list" },
                   if: -> { purchased_at.nil? }
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1,
                                       less_than_or_equal_to: InventoryItem::MAX_QUANTITY }
  validates :category, inclusion: { in: CATEGORIES }
  validate :inventory_item_in_same_household

  scope :to_buy, -> { where(purchased_at: nil).order(priority: :desc, created_at: :asc) }
  scope :purchased, -> { where.not(purchased_at: nil).order(purchased_at: :desc) }

  # Records the buyer and restocks the linked inventory item, if any.
  def purchase!(user)
    transaction do
      update!(purchased_by: user, purchased_at: Time.current)
      inventory_item&.with_lock do
        inventory_item.update!(quantity: [ inventory_item.quantity + quantity, InventoryItem::MAX_QUANTITY ].min)
      end
    end
  end

  private

  def inventory_item_in_same_household
    return if inventory_item.nil? || inventory_item.household_id == household_id

    errors.add(:inventory_item, "must belong to this household")
  end
end
