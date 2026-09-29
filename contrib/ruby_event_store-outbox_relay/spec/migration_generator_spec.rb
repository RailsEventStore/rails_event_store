# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe MigrationGenerator do
      let(:generator) { MigrationGenerator.new }
      let(:postgres_adapter) { RubyEventStore::ActiveRecord::DatabaseAdapter.from_string("postgresql") }
      let(:mysql_adapter) { RubyEventStore::ActiveRecord::DatabaseAdapter.from_string("mysql2") }
      let(:sqlite_adapter) { RubyEventStore::ActiveRecord::DatabaseAdapter.from_string("sqlite") }

      describe "#call" do
        specify "writes the generated migration to disk at migration_path and returns its path" do
          Dir.mktmpdir do |dir|
            path = generator.call(sqlite_adapter, dir)

            expect(path).to match(%r{\A#{Regexp.escape(dir)}/\d{14}_create_event_store_outbox_tables\.rb\z})
            expect(File.read(path)).to include("class CreateEventStoreOutboxTables < ActiveRecord::Migration[")
            expect(File.read(path)).to include("create_table :event_store_outbox_messages")
          end
        end
      end

      describe "#generate" do
        specify "returns the target path and migration content without writing anything to disk" do
          Dir.mktmpdir do |dir|
            path, content = generator.generate(sqlite_adapter, dir)

            expect(path).to match(%r{\A#{Regexp.escape(dir)}/\d{14}_create_event_store_outbox_tables\.rb\z})
            expect(content).to include("class CreateEventStoreOutboxTables < ActiveRecord::Migration[")
            expect(content).to include("create_table :event_store_outbox_messages")
            expect(Dir.children(dir)).to be_empty
          end
        end

        specify "renders uuid event ids for postgres" do
          Dir.mktmpdir do |dir|
            _, content = generator.generate(postgres_adapter, dir)

            expect(content).to include("t.uuid     :event_id,        null: false")
            expect(content).to include("t.uuid     :event_id,          null: false")
          end
        end

        %i[mysql_adapter sqlite_adapter].each do |adapter|
          specify "renders 36-character string event ids for #{adapter}" do
            Dir.mktmpdir do |dir|
              _, content = generator.generate(public_send(adapter), dir)

              expect(content).to include("t.string   :event_id,        null: false, limit: 36")
              expect(content).to include("t.string   :event_id,          null: false, limit: 36")
            end
          end
        end

        specify "creates the due index and the dead letters table, and never touches event_store_events" do
          Dir.mktmpdir do |dir|
            [postgres_adapter, mysql_adapter, sqlite_adapter].each do |adapter|
              _, content = generator.generate(adapter, dir)

              expect(content).to include('t.index    %i[next_attempt_at id], name: "index_event_store_outbox_messages_due"')
              expect(content).to include("create_table :event_store_outbox_dead_letters")
              expect(content).not_to include("add_column")
              expect(content).not_to include("published_at")
            end
          end
        end
      end

      describe "#migration_code (private)" do
        specify "renders the template with the current migration_version interpolated" do
          code = generator.send(:migration_code, sqlite_adapter)

          expect(code).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
          expect(code).to include("class CreateEventStoreOutboxTables")
        end
      end

      describe "#template (private)" do
        specify "loads the ERB source for the migration from the gem's own template file" do
          template = generator.send(:template, sqlite_adapter)

          expect(template).to be_a(ERB)
          expect(template.src).to include("class CreateEventStoreOutboxTables")
          expect(template.src).to include("migration_version")
        end

        specify "raises when the adapter has no matching template directory" do
          unknown_adapter = RubyEventStore::ActiveRecord::DatabaseAdapter::PostgreSQL.new
          allow(unknown_adapter).to receive(:adapter_name).and_return("unknown")

          expect { generator.send(:template, unknown_adapter) }.to raise_error(KeyError)
        end
      end

      describe "#migration_version (private)" do
        specify "returns ActiveRecord::Migration.current_version" do
          expect(generator.send(:migration_version)).to eq(::ActiveRecord::Migration.current_version)
        end
      end

      describe "#build_path (private)" do
        specify "joins the string form of migration_path with a timestamped migration filename" do
          migration_path = Object.new
          def migration_path.to_s
            "/custom/dir"
          end

          path = generator.send(:build_path, migration_path)

          expect(path).to match(%r{\A/custom/dir/\d{14}_create_event_store_outbox_tables\.rb\z})
        end
      end

      describe "#timestamp (private)" do
        specify "formats the given time as YYYYMMDDHHMMSS, defaulting to the current time" do
          fixed_time = Time.new(2026, 1, 2, 3, 4, 5)

          expect(generator.send(:timestamp, fixed_time)).to eq("20260102030405")
          expect(generator.send(:timestamp)).to match(/\A\d{14}\z/)
        end
      end
    end
  end
end
