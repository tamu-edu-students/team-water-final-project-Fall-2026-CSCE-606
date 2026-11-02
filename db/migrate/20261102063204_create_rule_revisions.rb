class CreateRuleRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :rule_revisions do |t|
      t.references :rule, null: false, foreign_key: true
      t.references :proposed_by, null: false, foreign_key: { to_table: :users }
      t.text :description, null: false
      t.text :reason
      t.integer :version, default: 1, null: false
      t.datetime :approved_at

      t.timestamps
    end
  end
end
