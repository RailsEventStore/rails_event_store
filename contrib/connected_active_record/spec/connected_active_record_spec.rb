require "spec_helper"
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'

module ConnectedActiveRecord
  RSpec.describe Repository do
    include SchemaHelper

    context 'like a repository' do
      around(:each) do |example|
        begin
          establish_database_connection
          load_database_schema
          example.run
        ensure
          drop_database
          close_database_connection
        end
      end

      let(:test_race_conditions_auto)  { !ENV['DATABASE_URL'].include?("sqlite") }
      let(:test_race_conditions_any)   { !ENV['DATABASE_URL'].include?("sqlite") }
      let(:test_binary)                { true }
      let(:test_change)                { true }

      it_behaves_like :event_repository, Repository
    end

    context 'multiple databases' do
      class PrimaryApplicationrecord < ActiveRecord::Base
        self.abstract_class = true
        establish_connection({
            adapter:  "sqlite3",
            primary: {
              database: "primary.db"
            },
            secondary: {
              database: "secondary.db"
            }
        })
        connects_to database: { writing: :primary, reading: :primary }
      end

      class SecondaryApplicationrecord < ActiveRecord::Base
        self.abstract_class = true
        establish_connection({
            adapter:  "sqlite3",
            primary: {
              database: "primary.db"
            },
            secondary: {
              database: "secondary.db"
            }
        })
        connects_to database: { writing: :secondary, reading: :secondary }
      end

      specify "each repository instance could have it's own database" do
        mapper = RubyEventStore::Mappers::NullMapper.new

        primary_repository  = Repository.new(PrimaryApplicationRecord)
        primary_reader      = RubyEventStore::SpecificationReader.new(primary_repository, mapper)
        primary_repository.append_to_stream(
          [primary_event = RubyEventStore::SRecord.new],
          RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
          RubyEventStore::ExpectedVersion.any
        )

        secondary_repository  = Repository.new(SecondaryApplicationRecord)
        secondary_reader      = RubyEventStore::SpecificationReader.new(secondary_repository, mapper)
        secondary_repository.append_to_stream(
          [secondary_event = RubyEventStore::SRecord.new],
          RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
          RubyEventStore::ExpectedVersion.any
        )

        read_from_primary = primary_reader.read.to_a
        read_from_secondary = secondary_reader.read.to_a
      end
    end
  end
end
