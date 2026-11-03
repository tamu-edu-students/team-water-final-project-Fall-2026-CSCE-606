class AddInventorySeededAtToHouseholds < ActiveRecord::Migration[8.1]
  def change
    # Set once the default room inventory is created, so deleted defaults stay deleted.
    add_column :households, :inventory_seeded_at, :datetime
  end
end
