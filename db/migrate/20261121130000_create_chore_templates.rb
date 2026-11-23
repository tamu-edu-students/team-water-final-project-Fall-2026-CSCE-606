class CreateChoreTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :chore_templates do |t|
      t.references :household, null: false, foreign_key: { on_delete: :cascade }
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :title, limit: 200, null: false
      t.text :description
      t.string :category, limit: 40, null: false, default: "General"
      t.string :frequency, null: false, default: "NONE"
      t.timestamps
    end

    add_index :chore_templates, "household_id, lower(title)", unique: true,
                                name: "index_chore_templates_on_household_and_title"
  end
end
