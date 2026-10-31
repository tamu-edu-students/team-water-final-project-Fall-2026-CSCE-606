class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_enum :recurrence_type, %w[NONE DAILY WEEKLY MONTHLY]

    create_table :events, primary_key: :event_id, id: :bigint do |t|
      t.references :household, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.bigint :created_by, null: false
      t.string :name, null: false, limit: 200
      t.text :description
      t.column :start_timestamp, :timestamptz, null: false
      t.column :end_timestamp, :timestamptz, null: false
      t.boolean :all_day, null: false, default: false
      t.enum :recurring, enum_type: "recurrence_type", null: false, default: "NONE"
      t.date :recurrence_until

      t.column :created_at, :timestamptz, null: false, default: -> { "now()" }
      t.column :updated_at, :timestamptz, null: false, default: -> { "now()" }
    end

    add_check_constraint :events, "end_timestamp > start_timestamp",
                         name: "events_end_after_start"
    add_foreign_key :events, :users, column: :created_by
    add_check_constraint :events,
                         "recurrence_until IS NULL OR recurring <> 'NONE'",
                         name: "events_until_needs_recurrence"
    add_index :events, [:household_id, :start_timestamp],
              name: "idx_events_household_start"

    create_table :event_attendees, primary_key: [:event_id, :user_id], id: false do |t|
      t.references :event, null: false, index: false,
                           foreign_key: { to_table: :events, primary_key: :event_id, on_delete: :cascade }
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
    end
    add_index :event_attendees, :user_id, name: "idx_event_attendees_user"

    create_table :event_exceptions, primary_key: [:event_id, :original_start], id: false do |t|
      t.references :event, null: false, index: false,
                           foreign_key: { to_table: :events, primary_key: :event_id, on_delete: :cascade }
      t.column :original_start, :timestamptz, null: false
      t.boolean :is_cancelled, null: false, default: false
      t.string :name, limit: 200
      t.text :description
      t.column :start_timestamp, :timestamptz
      t.column :end_timestamp, :timestamptz
    end
    add_check_constraint :event_exceptions,
                         "start_timestamp IS NULL OR end_timestamp IS NULL OR end_timestamp > start_timestamp",
                         name: "exceptions_end_after_start"
  end
end
