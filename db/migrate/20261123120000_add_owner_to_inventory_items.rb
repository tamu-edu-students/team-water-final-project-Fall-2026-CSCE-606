class AddOwnerToInventoryItems < ActiveRecord::Migration[8.1]
  def change
    add_column :inventory_items, :owner, :string, limit: 50
  end
end
