class AddInviteCodeToHouseholds < ActiveRecord::Migration[8.1]
  def change
    add_column :households, :invite_code, :string
    add_index :households, :invite_code, unique: true
  end
end
