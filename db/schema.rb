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

ActiveRecord::Schema[8.1].define(version: 2026_02_22_203012) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.integer "calories"
    t.string "category"
    t.datetime "created_at", null: false
    t.text "notes"
    t.date "performed_on"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.decimal "value"
    t.index ["user_id"], name: "index_activities_on_user_id"
  end

  create_table "keypair_auth_challenges", force: :cascade do |t|
    t.string "challenge", null: false
    t.boolean "consumed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "pubkey_hex"
    t.datetime "updated_at", null: false
    t.index ["challenge"], name: "index_keypair_auth_challenges_on_challenge", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "activity_level", default: "moderately_active"
    t.integer "blood_pressure_diastolic"
    t.integer "blood_pressure_systolic"
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.string "display_name"
    t.string "goal", default: "maintain"
    t.text "health_concerns"
    t.decimal "height", precision: 4, scale: 1
    t.string "npub", null: false
    t.integer "prayer_goal_minutes", default: 15
    t.string "pubkey_hex", null: false
    t.string "race_ethnicity"
    t.string "sex"
    t.string "timezone", default: "Eastern Time (US & Canada)"
    t.datetime "updated_at", null: false
    t.decimal "water_goal_cups", precision: 4, scale: 1
    t.decimal "weight", precision: 5, scale: 1
    t.index ["npub"], name: "index_users_on_npub", unique: true
    t.index ["pubkey_hex"], name: "index_users_on_pubkey_hex", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "users"
end
