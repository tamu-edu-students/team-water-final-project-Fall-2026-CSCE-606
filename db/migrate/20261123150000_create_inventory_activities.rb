class CreateInventoryActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_activities do |t|
      t.references :household, null: false, foreign_key: { on_delete: :cascade }
      t.references :inventory_item, foreign_key: { on_delete: :nullify }
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :action, null: false
      t.string :item_name, limit: 100, null: false
      t.string :room, null: false
      t.jsonb :details, null: false, default: {}
      t.timestamps
    end

    add_index :inventory_activities, %i[household_id updated_at]
    add_check_constraint :inventory_activities, "action IN ('added', 'updated', 'removed', 'restocked')",
                         name: "inventory_activities_valid_action"
  end
end
