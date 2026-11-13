class AddLowStockThresholdToInventoryItems < ActiveRecord::Migration[8.1]
  def change
    add_column :inventory_items, :low_stock_threshold, :integer, null: false, default: 0
    add_check_constraint :inventory_items, "low_stock_threshold >= 0 AND low_stock_threshold <= 9999",
                         name: "inventory_items_valid_low_stock_threshold"
  end
end
