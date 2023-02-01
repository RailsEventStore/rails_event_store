# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe "Gold master test for create table schema" do
      include SchemaHelper

      around do |example|
        establish_database_connection
        drop_database

        load_database_schema

        example.run
      ensure
        drop_database
        close_database_connection
      end

      specify "postgres" do
        skip unless ENV["DATABASE_URL"].include?("postgres")

        data_type = data_type_to_pg_type(ENV["DATA_TYPE"])

        create_event_store_events = pg_show_create_table("event_store_events")
        create_event_store_events_in_streams = pg_show_create_table("event_store_events_in_streams")

        expect(
          [create_event_store_events, create_event_store_events_in_streams].join("\n").gsub(/\s+/, " ")
        ).to eq <<~SCHEMA.strip.gsub(/\s+/, " ")
          Table "public.event_store_events"
             Column   |            Type                | Collation | Nullable |                    Default                     
          ------------+--------------------------------+-----------+----------+------------------------------------------------
           id         | bigint                         |           | not null | nextval('event_store_events_id_seq'::regclass)
           event_id   | uuid                           |           | not null |
           event_type | character varying              |           | not null |
           metadata   | #{data_type}                   |           |          |
           data       | #{data_type}                   |           | not null |
           created_at | timestamp(6) without time zone |           | not null |
           valid_at   | timestamp(6) without time zone |           |          |
          Indexes:
              "event_store_events_pkey" PRIMARY KEY, btree (id)
              "index_event_store_events_on_created_at" btree (created_at)
              "index_event_store_events_on_event_id" UNIQUE, btree (event_id)
              "index_event_store_events_on_event_type" btree (event_type)
              "index_event_store_events_on_valid_at" btree (valid_at)
          Table "public.event_store_events_in_streams"
             Column   |            Type                | Collation | Nullable |                          Default                          
          ------------+--------------------------------+-----------+----------+-----------------------------------------------------------
           id         | bigint                         |           | not null | nextval('event_store_events_in_streams_id_seq'::regclass)
           stream     | character varying              |           | not null |
           position   | integer                        |           |          |
           event_id   | uuid                           |           | not null |
           created_at | timestamp(6) without time zone |           | not null |
          Indexes:
              "event_store_events_in_streams_pkey" PRIMARY KEY, btree (id)
              "index_event_store_events_in_streams_on_created_at" btree (created_at)
              "index_event_store_events_in_streams_on_stream_and_event_id" UNIQUE, btree (stream, event_id)
              "index_event_store_events_in_streams_on_stream_and_position" UNIQUE, btree (stream, "position")
        SCHEMA
      end

      specify "mysql" do
        skip unless ENV["DATABASE_URL"].include?("mysql")

        my_sql_major_version = ::ActiveRecord::Base.connection.select_value("SELECT VERSION();").to_i
        collation = my_sql_major_version == 8 ? " COLLATE=utf8mb4_0900_ai_ci" : ""
        charset = my_sql_major_version == 8 ? "utf8mb4" : "latin1"
        int_lenght = my_sql_major_version == 8 ? "" : "(11)"
        bigint_lenght = my_sql_major_version == 8 ? "" : "(20)"

        create_event_store_events = mysql_show_create_table("event_store_events")
        create_event_store_events_in_streams = mysql_show_create_table("event_store_events_in_streams")

        expect([create_event_store_events, create_event_store_events_in_streams].join("\n")).to eq <<~SCHEMA.strip
            CREATE TABLE `event_store_events` (
              `id` bigint#{bigint_lenght} NOT NULL AUTO_INCREMENT,
              `event_id` varchar(36) NOT NULL,
              `event_type` varchar(255) NOT NULL,
              `metadata` blob,
              `data` blob NOT NULL,
              `created_at` datetime(6) NOT NULL,
              `valid_at` datetime(6) DEFAULT NULL,
              PRIMARY KEY (`id`),
              UNIQUE KEY `index_event_store_events_on_event_id` (`event_id`),
              KEY `index_event_store_events_on_created_at` (`created_at`),
              KEY `index_event_store_events_on_valid_at` (`valid_at`),
              KEY `index_event_store_events_on_event_type` (`event_type`)
            ) ENGINE=InnoDB DEFAULT CHARSET=#{charset}#{collation}
            CREATE TABLE `event_store_events_in_streams` (
              `id` bigint#{bigint_lenght} NOT NULL AUTO_INCREMENT,
              `stream` varchar(255) NOT NULL,
              `position` int#{int_lenght} DEFAULT NULL,
              `event_id` varchar(36) NOT NULL,
              `created_at` datetime(6) NOT NULL,
              PRIMARY KEY (`id`),
              UNIQUE KEY `index_event_store_events_in_streams_on_stream_and_event_id` (`stream`,`event_id`),
              UNIQUE KEY `index_event_store_events_in_streams_on_stream_and_position` (`stream`,`position`),
              KEY `index_event_store_events_in_streams_on_created_at` (`created_at`)
            ) ENGINE=InnoDB DEFAULT CHARSET=#{charset}#{collation}
        SCHEMA
      end

      specify "sqlite" do
        skip unless ENV["DATABASE_URL"].include?("sqlite")

        expect(::ActiveRecord::Base.connection.execute(<<~SQL).map { |x| x["sql"] }.join("\n")).to eq <<~SCHEMA.strip
            SELECT  sql
            FROM    sqlite_schema
            WHERE   NAME LIKE '%event_store_events%'
          SQL
          CREATE TABLE "event_store_events_in_streams" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "stream" varchar NOT NULL, "position" integer, "event_id" varchar(36) NOT NULL, "created_at" datetime(6) NOT NULL)
          CREATE UNIQUE INDEX "index_event_store_events_in_streams_on_stream_and_position" ON "event_store_events_in_streams" ("stream", "position")
          CREATE INDEX "index_event_store_events_in_streams_on_created_at" ON "event_store_events_in_streams" ("created_at")
          CREATE UNIQUE INDEX "index_event_store_events_in_streams_on_stream_and_event_id" ON "event_store_events_in_streams" ("stream", "event_id")
          CREATE TABLE "event_store_events" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "event_id" varchar(36) NOT NULL, "event_type" varchar NOT NULL, "metadata" blob, "data" blob NOT NULL, "created_at" datetime(6) NOT NULL, "valid_at" datetime(6))
          CREATE UNIQUE INDEX "index_event_store_events_on_event_id" ON "event_store_events" ("event_id")
          CREATE INDEX "index_event_store_events_on_created_at" ON "event_store_events" ("created_at")
          CREATE INDEX "index_event_store_events_on_valid_at" ON "event_store_events" ("valid_at")
          CREATE INDEX "index_event_store_events_on_event_type" ON "event_store_events" ("event_type")
        SCHEMA
      end

      private

      def data_type_to_pg_type(data_type)
        { "binary" => "bytea", "json" => "json", "jsonb" => "jsonb" }.fetch(data_type)
      end

      def pg_show_create_table(table_name)
        db_config = ::ActiveRecord::Base.connection_db_config
        <<~RESULT.strip
          #{IO.popen("psql #{db_config.adapter}://postgres:#{db_config.configuration_hash[:password]}@#{db_config.host}:#{db_config.configuration_hash[:port]}/#{db_config.database}  -c '\\d #{table_name}'").readlines.join}
        RESULT
      end

      def mysql_show_create_table(name)
        ::ActiveRecord::Base.connection.execute("SHOW CREATE TABLE #{name}").to_a.flatten.last
      end
    end
  end
end
