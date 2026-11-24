# One row of a household's inventory history. The item's name and room are copied in,
# so the history still reads correctly after the item is renamed or removed.
class InventoryActivity < ApplicationRecord
  ACTIONS = %w[added updated removed restocked].freeze
  FIELDS = { "name" => "Name", "owner" => "Owner", "quantity" => "Count", "low_stock_threshold" => "Alert at" }.freeze
  MERGE_WINDOW = 5.minutes

  belongs_to :household
  belongs_to :inventory_item, optional: true
  belongs_to :user, optional: true

  validates :action, inclusion: { in: ACTIONS }

  scope :recent_first, -> { order(updated_at: :desc, id: :desc) }

  # For "added" and "removed": remembers the item's count and owner at that moment.
  def self.log_snapshot(item, user, action)
    log(item, user, action, item.slice("quantity", "owner"))
  end

  # For "updated" and "restocked": records each tracked field's old and new value, if any changed.
  def self.log_changes(item, user, action = "updated")
    changes = item.saved_changes.slice(*FIELDS.keys)
    log(item, user, action, changes) if changes.any?
  end

  # Repeated +/- clicks by the same person become one row; a row that nets out to no change is dropped.
  def self.log_count_change(item, user)
    return unless item.saved_change_to_quantity?

    last = item.inventory_activities.order(:id).last
    return log_changes(item, user) unless last&.mergeable_count_change?(user)

    from = last.details["quantity"].first
    to = item.quantity
    from == to ? last.destroy! : last.update!(details: { "quantity" => [ from, to ] })
  end

  def self.log(item, user, action, details)
    create!(household: item.household, inventory_item: item, user:, action:,
            item_name: item.name, room: item.room, details:)
  end
  private_class_method :log

  def mergeable_count_change?(user)
    user_id == user.id && action == "updated" && details.keys == [ "quantity" ] &&
      updated_at > MERGE_WINDOW.ago
  end

  def actor_name
    user&.name || "Former roommate"
  end

  def room_label
    InventoryItem::ROOMS.fetch(room)
  end

  # Readable details, e.g. ["Count 3 → 2", "Owner Shared → Alice"].
  def change_lines
    if action.in?(%w[added removed])
      [ "Count #{details['quantity']}", "Owner #{owner_text(details['owner'])}" ]
    else
      details.map do |field, (from, to)|
        from, to = [ from, to ].map { |value| field == "owner" ? owner_text(value) : value }
        "#{FIELDS.fetch(field)} #{from} → #{to}"
      end
    end
  end

  private

  def owner_text(owner)
    owner.presence || "Shared"
  end
end
