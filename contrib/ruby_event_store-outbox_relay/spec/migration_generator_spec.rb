# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe MigrationGenerator do
      let(:generator) { MigrationGenerator.new }

      describe "#call" do
        specify "writes the generated migration to disk at migration_path and returns its path" do
          Dir.mktmpdir do |dir|
            path = generator.call(dir)

            expect(path).to match(%r{\A#{Regexp.escape(dir)}/\d{14}_add_published_at_to_event_store_events\.rb\z})
            expect(File.read(path)).to include("class AddPublishedAtToEventStoreEvents < ActiveRecord::Migration[")
            expect(File.read(path)).to include("add_column :event_store_events,")
          end
        end
      end

      describe "#generate" do
        specify "returns the target path and migration content without writing anything to disk" do
          Dir.mktmpdir do |dir|
            path, content = generator.generate(dir)

            expect(path).to match(%r{\A#{Regexp.escape(dir)}/\d{14}_add_published_at_to_event_store_events\.rb\z})
            expect(content).to include("class AddPublishedAtToEventStoreEvents < ActiveRecord::Migration[")
            expect(content).to include("add_column :event_store_events,")
            expect(Dir.children(dir)).to be_empty
          end
        end
      end

      describe "#migration_code (private)" do
        specify "renders the template with the current migration_version interpolated" do
          code = generator.send(:migration_code)

          expect(code).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
          expect(code).to include("class AddPublishedAtToEventStoreEvents")
        end
      end

      describe "#template (private)" do
        specify "loads the ERB source for the migration from the gem's own template file" do
          template = generator.send(:template)

          expect(template).to be_a(ERB)
          expect(template.src).to include("class AddPublishedAtToEventStoreEvents")
          expect(template.src).to include("migration_version")
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

          expect(path).to match(%r{\A/custom/dir/\d{14}_add_published_at_to_event_store_events\.rb\z})
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
