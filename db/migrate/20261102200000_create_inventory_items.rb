class CreateInventoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_items do |t|
      t.references :household, null: false, foreign_key: { on_delete: :cascade }
      t.string :room, null: false
      t.string :name, null: false, limit: 100
      t.integer :quantity, null: false, default: 1

      t.timestamps
    end

    add_check_constraint :inventory_items,
                         "room IN ('living_room', 'kitchen', 'bedroom', 'bathroom', 'patio')",
                         name: "inventory_items_valid_room"
    add_check_constraint :inventory_items, "quantity >= 0 AND quantity <= 9999",
                         name: "inventory_items_valid_quantity"
    add_index :inventory_items, "household_id, room, lower(name)", unique: true,
              name: "index_inventory_items_on_household_room_and_name"
  end
end
