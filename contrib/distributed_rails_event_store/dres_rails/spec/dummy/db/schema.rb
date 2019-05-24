# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_08_09_123950) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "dres_rails_queue_jobs", force: :cascade do |t|
    t.integer "queue_id", null: false
    t.string "event_id", null: false
    t.string "state", null: false
    t.index ["queue_id", "event_id"], name: "index_dres_rails_queue_jobs_on_queue_id_and_event_id"
  end

  create_table "dres_rails_queues", force: :cascade do |t|
    t.string "name", null: false
    t.string "last_processed_event_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_dres_rails_queues_on_name", unique: true
  end

end
