# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe "Gold master test for schema" do
      include SchemaHelper

      specify do
        establish_database_connection
        drop_database

        load_database_schema

        expect(dump_schema.strip).to eq expected_schema
      ensure
        drop_database
        close_database_connection
      end

      private

      def expected_schema
        if ENV["DATABASE_URL"].include?("postgres")
          data_type = ENV["DATA_TYPE"]
          <<~SCHEMA.strip
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

            ActiveRecord::Schema[7.0].define(version: 2022_12_08_155138) do
              # These are extensions that must be enabled in order to support this database
              enable_extension \"plpgsql\"

              create_table \"event_store_events\", force: :cascade do |t|
                t.uuid \"event_id\", null: false
                t.string \"event_type\", null: false
                t.#{data_type} \"metadata\"
                t.#{data_type} \"data\", null: false
                t.datetime \"created_at\", precision: nil, null: false
                t.datetime \"valid_at\", precision: nil
                t.index [\"created_at\"], name: \"index_event_store_events_on_created_at\"
                t.index [\"event_id\"], name: \"index_event_store_events_on_event_id\", unique: true
                t.index [\"event_type\"], name: \"index_event_store_events_on_event_type\"
                t.index [\"valid_at\"], name: \"index_event_store_events_on_valid_at\"
              end

              create_table \"event_store_events_in_streams\", force: :cascade do |t|
                t.string \"stream\", null: false
                t.integer \"position\"
                t.uuid \"event_id\", null: false
                t.datetime \"created_at\", precision: nil, null: false
                t.index [\"created_at\"], name: \"index_event_store_events_in_streams_on_created_at\"
                t.index [\"stream\", \"event_id\"], name: \"index_event_store_events_in_streams_on_stream_and_event_id\", unique: true
                t.index [\"stream\", \"position\"], name: \"index_event_store_events_in_streams_on_stream_and_position\", unique: true
              end

            end
          SCHEMA
        elsif ENV["DATABASE_URL"].include?("mysql")
          <<~SCHEMA.strip
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

            ActiveRecord::Schema[7.0].define(version: 0) do
              create_table "event_store_events", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
                t.string "event_id", limit: 36, null: false
                t.string "event_type", null: false
                t.binary "metadata"
                t.binary "data", null: false
                t.datetime "created_at", null: false
                t.datetime "valid_at"
                t.index ["created_at"], name: "index_event_store_events_on_created_at"
                t.index ["event_id"], name: "index_event_store_events_on_event_id", unique: true
                t.index ["event_type"], name: "index_event_store_events_on_event_type"
                t.index ["valid_at"], name: "index_event_store_events_on_valid_at"
              end

              create_table "event_store_events_in_streams", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
                t.string "stream", null: false
                t.integer "position"
                t.string "event_id", limit: 36, null: false
                t.datetime "created_at", null: false
                t.index ["created_at"], name: "index_event_store_events_in_streams_on_created_at"
                t.index ["stream", "event_id"], name: "index_event_store_events_in_streams_on_stream_and_event_id", unique: true
                t.index ["stream", "position"], name: "index_event_store_events_in_streams_on_stream_and_position", unique: true
              end

            end
          SCHEMA
        else
          <<~SCHEMA.strip
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

            ActiveRecord::Schema[7.0].define(version: 0) do
              create_table \"event_store_events\", force: :cascade do |t|
                t.string \"event_id\", limit: 36, null: false
                t.string \"event_type\", null: false
                t.binary \"metadata\"
                t.binary \"data\", null: false
                t.datetime \"created_at\", null: false
                t.datetime \"valid_at\"
                t.index [\"created_at\"], name: \"index_event_store_events_on_created_at\"
                t.index [\"event_id\"], name: \"index_event_store_events_on_event_id\", unique: true
                t.index [\"event_type\"], name: \"index_event_store_events_on_event_type\"
                t.index [\"valid_at\"], name: \"index_event_store_events_on_valid_at\"
              end

              create_table \"event_store_events_in_streams\", force: :cascade do |t|
                t.string \"stream\", null: false
                t.integer \"position\"
                t.string \"event_id\", limit: 36, null: false
                t.datetime \"created_at\", null: false
                t.index [\"created_at\"], name: \"index_event_store_events_in_streams_on_created_at\"
                t.index [\"stream\", \"event_id\"], name: \"index_event_store_events_in_streams_on_stream_and_event_id\", unique: true
                t.index [\"stream\", \"position\"], name: \"index_event_store_events_in_streams_on_stream_and_position\", unique: true
              end

            end
          SCHEMA
        end
      end
    end
  end
end
