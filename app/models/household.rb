class Household < ApplicationRecord
  belongs_to :creator, class_name: "User"

  has_many :household_memberships, dependent: :destroy
  has_many :users, through: :household_memberships
  has_many :events, dependent: :destroy
  has_many :chores, dependent: :destroy

  has_secure_token :invite_code

  # Expense association
  has_many :expenses, dependent: :destroy

  # Rules association
  has_many :rules, dependent: :destroy

  # Inventory association
  has_many :inventory_items, dependent: :delete_all

  validates :name, presence: true
  validates :invite_code, uniqueness: true, allow_nil: true

  def admin?(user)
    user.present? && (creator_id == user.id || household_memberships.exists?(user_id: user.id, role: "admin"))
  end

  # Adds the starter items once; the lock stops two first visits from seeding twice.
  def ensure_default_inventory!
    return if inventory_seeded_at?

    with_lock do
      next if inventory_seeded_at?

      InventoryItem::DEFAULTS.each do |room, items|
        items.each do |name, quantity|
          inventory_items.find_or_create_by!(room:, name:) { |item| item.quantity = quantity }
        end
      end
      update!(inventory_seeded_at: Time.current)
    end
  end
end
