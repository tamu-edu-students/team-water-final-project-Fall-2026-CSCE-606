class CreateNotificationPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_preferences do |t|
      t.references :user, null: false,
                   foreign_key: true,
                   index: { unique: true }

      t.boolean :email_bills, default: true, null: false
      t.boolean :email_chores, default: true, null: false
      t.boolean :email_household_activity,
                default: true, null: false

      t.timestamps
    end
  end
end
