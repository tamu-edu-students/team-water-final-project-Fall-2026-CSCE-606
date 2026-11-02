class CreateRuleVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :rule_votes do |t|
      t.references :rule, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :decision, null: false

      t.timestamps
    end

    add_index :rule_votes, [ :rule_id, :user_id ], unique: true
  end
end
