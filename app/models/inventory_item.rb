class InventoryItem < ApplicationRecord
  ROOMS = {
    "living_room" => "Living room",
    "kitchen" => "Kitchen",
    "bedroom" => "Bedroom",
    "bathroom" => "Bathroom",
    "patio" => "Patio"
  }.freeze

  ROOM_ICONS = {
    "living_room" => "🛋️",
    "kitchen" => "🍳",
    "bedroom" => "🛏️",
    "bathroom" => "🛁",
    "patio" => "🪴"
  }.freeze

  MAX_QUANTITY = 9_999

  # Starter items created for each room the first time a household opens its inventory.
  DEFAULTS = {
    "living_room" => { "Sofa" => 1, "Coffee table" => 1, "TV" => 1, "Floor lamp" => 1, "Cushions" => 4 },
    "kitchen" => { "Plates" => 6, "Cups" => 6, "Cooking pots" => 2, "Dish soap" => 1, "Trash bags" => 20 },
    "bedroom" => { "Bed" => 1, "Pillows" => 2, "Bedsheets" => 2, "Hangers" => 10 },
    "bathroom" => { "Toilet paper" => 6, "Hand soap" => 1, "Towels" => 4, "Shampoo" => 1 },
    "patio" => { "Chairs" => 2, "Outdoor table" => 1, "Plants" => 3, "Broom" => 1 }
  }.freeze

  belongs_to :household

  normalizes :name, with: ->(name) { name.squish }

  validates :room, inclusion: { in: ROOMS.keys }
  validates :name, presence: true, length: { maximum: 100 },
                   uniqueness: { scope: %i[household_id room], case_sensitive: false,
                                 message: "already exists in this room" }
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0,
                                       less_than_or_equal_to: MAX_QUANTITY }

  scope :out_of_stock, -> { where(quantity: 0) }

  def room_label
    ROOMS.fetch(room)
  end

  def out_of_stock?
    quantity.zero?
  end
end
