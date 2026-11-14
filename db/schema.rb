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

ActiveRecord::Schema[8.1].define(version: 2026_11_14_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "task_completions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "task_id", null: false
    t.date "completed_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id"], name: "index_task_completions_on_task_id"
    t.index ["user_id", "completed_on"], name: "index_task_completions_on_user_id_and_completed_on"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "daily_recommendation_task_id"
    t.date "daily_recommendation_date"
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["daily_recommendation_task_id"], name: "index_users_on_daily_recommendation_task_id"
  end

  add_foreign_key "task_completions", "tasks", on_delete: :cascade
  add_foreign_key "task_completions", "users", on_delete: :cascade
  add_foreign_key "tasks", "users", on_delete: :cascade
  add_foreign_key "users", "tasks", column: "daily_recommendation_task_id", on_delete: :nullify
end
