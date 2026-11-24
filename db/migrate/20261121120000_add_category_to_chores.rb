class AddCategoryToChores < ActiveRecord::Migration[8.1]
  CATEGORIES = %w[General Kitchen Bathroom Cleaning Laundry Trash Outdoor].freeze

  def change
    add_column :chores, :category, :string, limit: 40, null: false, default: "General"
    add_index :chores, %i[household_id category]
    add_check_constraint :chores,
                         "category IN (#{CATEGORIES.map { |c| "'#{c}'" }.join(', ')})",
                         name: "chores_valid_category"
  end
end
