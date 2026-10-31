# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_31_122200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "recurrence_type", ["NONE", "DAILY", "WEEKLY", "MONTHLY"]

  create_table "chore_assignments", id: false, force: :cascade do |t|
    t.bigint "chore_id", null: false
    t.bigint "user_id", null: false
    t.index ["chore_id", "user_id"], name: "index_chore_assignments_on_chore_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_chore_assignments_on_user_id"
  end

  create_table "chores", force: :cascade do |t|
    t.bigint "household_id", null: false
    t.bigint "created_by_id", null: false
    t.string "title", limit: 200, null: false
    t.text "description"
    t.timestamptz "due_at"
    t.string "frequency", default: "NONE", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_chores_on_created_by_id"
    t.index ["household_id", "due_at"], name: "index_chores_on_household_id_and_due_at"
    t.index ["household_id"], name: "index_chores_on_household_id"
    t.check_constraint "frequency::text = ANY (ARRAY['NONE'::character varying, 'DAILY'::character varying, 'WEEKLY'::character varying, 'MONTHLY'::character varying]::text[])", name: "chores_valid_frequency"
  end

  create_table "event_attendees", id: false, force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "idx_event_attendees_user"
  end

  create_table "event_exceptions", id: false, force: :cascade do |t|
    t.bigint "event_id", null: false
    t.timestamptz "original_start", null: false
    t.boolean "is_cancelled", default: false, null: false
    t.string "name", limit: 200
    t.text "description"
    t.timestamptz "start_timestamp"
    t.timestamptz "end_timestamp"
    t.check_constraint "start_timestamp IS NULL OR end_timestamp IS NULL OR end_timestamp > start_timestamp", name: "exceptions_end_after_start"
  end

  create_table "events", primary_key: "event_id", force: :cascade do |t|
    t.bigint "household_id", null: false
    t.bigint "created_by", null: false
    t.string "name", limit: 200, null: false
    t.text "description"
    t.timestamptz "start_timestamp", null: false
    t.timestamptz "end_timestamp", null: false
    t.boolean "all_day", default: false, null: false
    t.enum "recurring", default: "NONE", null: false, enum_type: "recurrence_type"
    t.date "recurrence_until"
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.index ["household_id", "start_timestamp"], name: "idx_events_household_start"
    t.check_constraint "end_timestamp > start_timestamp", name: "events_end_after_start"
    t.check_constraint "recurrence_until IS NULL OR recurring <> 'NONE'::recurrence_type", name: "events_until_needs_recurrence"
  end

  create_table "household_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "household_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "member", null: false
    t.index ["household_id"], name: "index_household_memberships_on_household_id"
    t.index ["user_id", "household_id"], name: "index_memberships_on_user_and_household", unique: true
    t.index ["user_id"], name: "index_household_memberships_on_user_id"
    t.check_constraint "role::text = ANY (ARRAY['admin'::character varying, 'member'::character varying]::text[])", name: "household_memberships_valid_role"
  end

  create_table "households", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "creator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invite_code"
    t.index ["creator_id"], name: "index_households_on_creator_id"
    t.index ["invite_code"], name: "index_households_on_invite_code", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "chore_assignments", "chores", on_delete: :cascade
  add_foreign_key "chore_assignments", "users", on_delete: :cascade
  add_foreign_key "chores", "households", on_delete: :cascade
  add_foreign_key "chores", "users", column: "created_by_id"
  add_foreign_key "event_attendees", "events", primary_key: "event_id", on_delete: :cascade
  add_foreign_key "event_attendees", "users", on_delete: :cascade
  add_foreign_key "event_exceptions", "events", primary_key: "event_id", on_delete: :cascade
  add_foreign_key "events", "households", on_delete: :cascade
  add_foreign_key "events", "users", column: "created_by"
  add_foreign_key "household_memberships", "households"
  add_foreign_key "household_memberships", "users"
  add_foreign_key "households", "users", column: "creator_id"
end
