class CreateShoppingItems < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_items do |t|
      t.references :household, null: false, foreign_key: { on_delete: :cascade }
      t.references :inventory_item, foreign_key: { on_delete: :nullify }
      t.references :added_by, null: false, foreign_key: { to_table: :users }
      t.references :purchased_by, foreign_key: { to_table: :users }
      t.string :name, null: false, limit: 100
      t.integer :quantity, null: false, default: 1
      t.integer :priority, null: false, default: 1
      t.string :category, null: false, default: "Groceries"
      t.datetime :purchased_at

      t.timestamps
    end

    add_check_constraint :shopping_items, "quantity >= 1 AND quantity <= 9999",
                         name: "shopping_items_valid_quantity"
    add_check_constraint :shopping_items, "priority IN (0, 1, 2)", name: "shopping_items_valid_priority"
    # The same item can be on the list once until it is bought.
    add_index :shopping_items, "household_id, lower(name)", unique: true, where: "purchased_at IS NULL",
              name: "index_shopping_items_on_household_and_open_name"
  end
end
