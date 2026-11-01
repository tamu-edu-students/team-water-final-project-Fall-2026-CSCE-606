class AddDueDateToExpenses < ActiveRecord::Migration[8.1]
  def change
    add_column :expenses, :due_date, :date
    add_index :expenses, :due_date
  end
end
