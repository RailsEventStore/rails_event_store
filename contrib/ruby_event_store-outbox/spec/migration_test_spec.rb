# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Outbox
    ::RSpec.describe "Gold master test for create outbox table schema", :db do
      include SchemaHelper

      specify "mysql" do
        skip unless ENV["DATABASE_URL"].include?("mysql")

        my_sql_major_version = ::ActiveRecord::Base.connection.select_value("SELECT VERSION();").to_i
        collation = my_sql_major_version == 8 ? " COLLATE=utf8mb4_0900_ai_ci" : ""
        charset = my_sql_major_version == 8 ? "utf8mb4" : "latin1"
        bigint_lenght = my_sql_major_version == 8 ? "" : "(20)"

        expect(mysql_show_create_table("event_store_outbox")).to eq <<~SCHEMA.strip
          CREATE TABLE `event_store_outbox` (
            `id` bigint#{bigint_lenght} NOT NULL AUTO_INCREMENT,
            `split_key` varchar(255) DEFAULT NULL,
            `format` varchar(255) NOT NULL,
            `payload` blob NOT NULL,
            `created_at` datetime(6) NOT NULL,
            `enqueued_at` datetime(6) DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `index_event_store_outbox_for_pool` (`format`,`enqueued_at`,`split_key`),
            KEY `index_event_store_outbox_for_clear` (`created_at`,`enqueued_at`)
          ) ENGINE=InnoDB DEFAULT CHARSET=#{charset}#{collation}
        SCHEMA

        expect(mysql_show_create_table("event_store_outbox_locks")).to eq <<~SCHEMA.strip
       CREATE TABLE `event_store_outbox_locks` (
         `id` bigint#{bigint_lenght} NOT NULL AUTO_INCREMENT,
         `format` varchar(255) NOT NULL,
         `split_key` varchar(255) NOT NULL,
         `locked_at` datetime(6) DEFAULT NULL,
         `locked_by` varchar(36) DEFAULT NULL,
         PRIMARY KEY (`id`),
         UNIQUE KEY `index_event_store_outbox_locks_for_locking` (`format`,`split_key`)
       ) ENGINE=InnoDB DEFAULT CHARSET=#{charset}#{collation}
        SCHEMA
      end

      specify "sqlite" do
        skip unless ENV["DATABASE_URL"].include?("sqlite")

        expect(::ActiveRecord::Base.connection.execute(<<~SQL).map { |x| x["sql"] }.join("\n")).to eq <<~SCHEMA.strip
          SELECT  sql
          FROM    sqlite_schema
          WHERE   NAME LIKE '%event_store_outbox%'
        SQL
          CREATE TABLE "event_store_outbox" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "split_key" varchar, "format" varchar NOT NULL, "payload" blob NOT NULL, "created_at" datetime(6) NOT NULL, "enqueued_at" datetime(6))
          CREATE INDEX "index_event_store_outbox_for_pool" ON "event_store_outbox" ("format", "enqueued_at", "split_key")
          CREATE INDEX "index_event_store_outbox_for_clear" ON "event_store_outbox" ("created_at", "enqueued_at")
          CREATE TABLE "event_store_outbox_locks" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "format" varchar NOT NULL, "split_key" varchar NOT NULL, "locked_at" datetime(6), "locked_by" varchar(36))
          CREATE UNIQUE INDEX "index_event_store_outbox_locks_for_locking" ON "event_store_outbox_locks" ("format", "split_key")
        SCHEMA
      end

      private

      def mysql_show_create_table(name)
        ::ActiveRecord::Base.connection.execute("SHOW CREATE TABLE #{name}").to_a.flatten.last
      end
    end
  end
end
