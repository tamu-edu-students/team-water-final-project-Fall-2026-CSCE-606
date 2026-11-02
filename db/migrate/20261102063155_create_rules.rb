class CreateRules < ActiveRecord::Migration[8.1]
  def change
    create_table :rules do |t|
      t.references :household, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description, null: false
      t.string :category, default: "General", null: false
      t.string :status, default: "proposed", null: false
      t.datetime :approved_at
      t.references :parent_rule, foreign_key: { to_table: :rules }
      t.text :amendment_reason

      t.timestamps
    end

    add_index :rules, :status
  end
end
