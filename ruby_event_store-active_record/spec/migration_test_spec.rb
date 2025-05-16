# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe "golden master test for create table schema" do
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
        skip unless postgres?

        data_type = data_type_to_pg_type(ENV["DATA_TYPE"])

        expect(pg_schema("event_store_events").gsub(/\s+/, " ")).to eq <<~SCHEMA.strip.gsub(/\s+/, " ")
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
          Referenced by:
              TABLE "event_store_events_in_streams" CONSTRAINT "fk_rails_c8d52b5857" FOREIGN KEY (event_id) REFERENCES event_store_events(event_id)
        SCHEMA

        expect(pg_schema("event_store_events_in_streams").gsub(/\s+/, " ")).to eq <<~SCHEMA.strip.gsub(/\s+/, " ")
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
              "index_event_store_events_in_streams_on_event_id" btree (event_id)
              "index_event_store_events_in_streams_on_stream_and_event_id" UNIQUE, btree (stream, event_id)
              "index_event_store_events_in_streams_on_stream_and_position" UNIQUE, btree (stream, "position")
          Foreign-key constraints:
              "fk_rails_c8d52b5857" FOREIGN KEY (event_id) REFERENCES event_store_events(event_id)
        SCHEMA
      end

      specify "mysql" do
        skip unless mysql?

        data_type = data_type_to_mysql_type(ENV["DATA_TYPE"])

        mysql_major_version = ::ActiveRecord::Base.connection.select_value("SELECT VERSION();").to_i
        collation = mysql_major_version == 8 ? " COLLATE=utf8mb4_0900_ai_ci" : ""
        charset = mysql_major_version == 8 ? "utf8mb4" : "latin1"
        int_lenght = mysql_major_version == 8 ? "" : "(11)"
        bigint_lenght = mysql_major_version == 8 ? "" : "(20)"

        expect(mysql_schema("event_store_events")).to eq <<~SCHEMA.strip
          CREATE TABLE `event_store_events` (
            `id` bigint#{bigint_lenght} NOT NULL AUTO_INCREMENT,
            `event_id` varchar(36) NOT NULL,
            `event_type` varchar(255) NOT NULL,
            `metadata` #{data_type}#{" DEFAULT NULL" if data_type == "json"},
            `data` #{data_type} NOT NULL,
            `created_at` datetime(6) NOT NULL,
            `valid_at` datetime(6) DEFAULT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `index_event_store_events_on_event_id` (`event_id`),
            KEY `index_event_store_events_on_event_type` (`event_type`),
            KEY `index_event_store_events_on_created_at` (`created_at`),
            KEY `index_event_store_events_on_valid_at` (`valid_at`)
          ) ENGINE=InnoDB DEFAULT CHARSET=#{charset}#{collation}
        SCHEMA

        expect(mysql_schema("event_store_events_in_streams")).to eq <<~SCHEMA.strip
          CREATE TABLE `event_store_events_in_streams` (
            `id` bigint#{bigint_lenght} NOT NULL AUTO_INCREMENT,
            `stream` varchar(255) NOT NULL,
            `position` int#{int_lenght} DEFAULT NULL,
            `event_id` varchar(36) NOT NULL,
            `created_at` datetime(6) NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `index_event_store_events_in_streams_on_stream_and_event_id` (`stream`,`event_id`),
            UNIQUE KEY `index_event_store_events_in_streams_on_stream_and_position` (`stream`,`position`),
            KEY `index_event_store_events_in_streams_on_event_id` (`event_id`),
            KEY `index_event_store_events_in_streams_on_created_at` (`created_at`),
            CONSTRAINT `fk_rails_c8d52b5857` FOREIGN KEY (`event_id`) REFERENCES `event_store_events` (`event_id`)
          ) ENGINE=InnoDB DEFAULT CHARSET=#{charset}#{collation}
        SCHEMA
      end

      specify "sqlite" do
        skip unless sqlite?

        expect(sqlite_schema("event_store_events")).to eq <<~SCHEMA.strip
          CREATE TABLE "event_store_events" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "event_id" varchar(36) NOT NULL, "event_type" varchar NOT NULL, "metadata" blob, "data" blob NOT NULL, "created_at" datetime(6) NOT NULL, "valid_at" datetime(6))
          CREATE UNIQUE INDEX "index_event_store_events_on_event_id" ON "event_store_events" ("event_id")
          CREATE INDEX "index_event_store_events_on_event_type" ON "event_store_events" ("event_type")
          CREATE INDEX "index_event_store_events_on_created_at" ON "event_store_events" ("created_at")
          CREATE INDEX "index_event_store_events_on_valid_at" ON "event_store_events" ("valid_at")
        SCHEMA

        expect(sqlite_schema("event_store_events_in_streams")).to eq <<~SCHEMA.strip
          CREATE TABLE "event_store_events_in_streams" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "stream" varchar NOT NULL, "position" integer DEFAULT NULL, "event_id" varchar(36) NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c8d52b5857"
          FOREIGN KEY ("event_id")
            REFERENCES "event_store_events" ("event_id")
          )
          CREATE INDEX "index_event_store_events_in_streams_on_event_id" ON "event_store_events_in_streams" ("event_id")
          CREATE INDEX "index_event_store_events_in_streams_on_created_at" ON "event_store_events_in_streams" ("created_at")
          CREATE UNIQUE INDEX "index_event_store_events_in_streams_on_stream_and_position" ON "event_store_events_in_streams" ("stream", "position")
          CREATE UNIQUE INDEX "index_event_store_events_in_streams_on_stream_and_event_id" ON "event_store_events_in_streams" ("stream", "event_id")
        SCHEMA
      end

      private

      def data_type_to_pg_type(data_type)
        { "binary" => "bytea", "json" => "json", "jsonb" => "jsonb" }.fetch(data_type)
      end

      def data_type_to_mysql_type(data_type)
        { "binary" => "blob", "json" => "json" }.fetch(data_type)
      end

      def sqlite_schema(name)
        ::ActiveRecord::Base.connection.execute(<<~SQL).map { |x| x["sql"] }.join("\n")
             SELECT  sql
             FROM    sqlite_schema
             WHERE   tbl_name = '#{name}'
           SQL
      end

      def pg_schema(table_name)
        IO.popen("psql #{::ActiveRecord::Base.connection_db_config.url} -c '\\d #{table_name}'").readlines.join.strip
      end

      def mysql_schema(name)
        ::ActiveRecord::Base.connection.execute("SHOW CREATE TABLE #{name}").to_a.flatten.last
      end
    end
  end
end
