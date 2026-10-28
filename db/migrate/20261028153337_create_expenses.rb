class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :household, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.decimal :amount
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.decimal :total_amount
      t.date :expense_date

      t.timestamps
    end
  end
end
