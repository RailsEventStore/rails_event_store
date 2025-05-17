# frozen_string_literal: true

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

ActiveRecord::Schema[7.0].define(version: 2018_08_09_123950) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "dres_rails_queue_jobs", force: :cascade do |t|
    t.integer "queue_id", null: false
    t.string "event_id", null: false
    t.string "state", null: false
    t.index %w[queue_id event_id], name: "index_dres_rails_queue_jobs_on_queue_id_and_event_id"
  end

  create_table "dres_rails_queues", force: :cascade do |t|
    t.string "name", null: false
    t.string "last_processed_event_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_dres_rails_queues_on_name", unique: true
  end
end
