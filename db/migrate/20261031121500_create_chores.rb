class CreateChores < ActiveRecord::Migration[8.1]
  def change
    create_table :chores do |t|
      t.references :household, null: false, foreign_key: { on_delete: :cascade }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false, limit: 200
      t.text :description
      t.column :due_at, :timestamptz
      t.string :frequency, null: false, default: "NONE"

      t.timestamps
    end

    add_check_constraint :chores,
                         "frequency IN ('NONE', 'DAILY', 'WEEKLY', 'MONTHLY')",
                         name: "chores_valid_frequency"
    add_index :chores, [:household_id, :due_at]

    create_table :chore_assignments, id: false do |t|
      t.references :chore, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
    end
    add_index :chore_assignments, [:chore_id, :user_id], unique: true
    add_index :chore_assignments, :user_id
  end
end
