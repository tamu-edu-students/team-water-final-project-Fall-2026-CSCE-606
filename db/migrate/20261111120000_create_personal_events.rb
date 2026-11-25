class CreatePersonalEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :personal_events do |t|
      t.references :creator, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :household, null: true, foreign_key: { on_delete: :cascade }
      t.string :title, null: false, limit: 200
      t.text :description
      t.date :event_date, null: false
      t.string :visibility, null: false, default: "private"
      t.timestamps
    end
    add_check_constraint :personal_events, "visibility IN ('private', 'shared')",
                         name: "personal_events_valid_visibility"
    add_index :personal_events, [ :creator_id, :event_date ]
    add_index :personal_events, [ :household_id, :event_date ]

    create_table :personal_event_attendees do |t|
      t.references :personal_event, null: false,
                                   foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
    add_index :personal_event_attendees, [ :personal_event_id, :user_id ], unique: true,
              name: "index_personal_event_attendees_on_event_and_user"
  end
end
