require 'spec_helper'
require 'active_record'
require 'ruby_event_store'
require 'rails_event_store_active_record'
require 'ruby_event_store/spec/event_repository_lint'
require_relative '../../lib/subprocess_helper'


class EventA2 < RubyEventStore::Event
end

RSpec.describe "v1_v2_migration" do
  include SchemaHelper
  include SubprocessHelper

  specify do
    begin
      establish_database_connection
      load_database_schema
      skip("in-memory sqlite cannot run this test") if ENV['DATABASE_URL'].include?(":memory:")
      dump_current_schema
      drop_existing_tables_to_clean_state

      run_in_subprocess(File.join(__dir__, 'schema/Gemfile'), <<~EOF)
        require 'rails/generators'
        require 'rails_event_store_active_record'
        require 'ruby_event_store'
        require 'logger'
        require '../../../lib/migrator'

        $verbose = ENV.has_key?('VERBOSE') ? true : false
        ActiveRecord::Schema.verbose = $verbose
        ActiveRecord::Base.logger = Logger.new(STDOUT) if $verbose
        ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'].gsub("db.sqlite3", "../../db.sqlite3"))

        gem_path = $LOAD_PATH.find { |path| path.match(/rails_event_store_active_record/) }
        Migrator.new(File.expand_path('rails_event_store_active_record/generators/templates', gem_path))
          .run_migration('create_event_store_events', 'migration')

        class EventAll < RubyEventStore::Event
        end
        class EventA1 < RubyEventStore::Event
        end
        class EventA2 < RubyEventStore::Event
        end
        class EventB1 < RubyEventStore::Event
        end
        class EventB2 < RubyEventStore::Event
        end

        client = RubyEventStore::Client.new(
          repository: RailsEventStoreActiveRecord::EventRepository.new
        )
        client.append_to_stream(EventAll.new(data: {
          all: true,
          a: 1,
          text: "text",
        }, event_id: "94b297a3-5a29-4942-9038-3efeceb4d905"))
        client.append_to_stream(EventAll.new(data: {
          all: true,
          a: 2,
          date: Date.new(2017, 10, 11),
        }, event_id: "6a31b594-7d8f-428b-916f-496f6da05bfd"))
        client.append_to_stream(EventAll.new(data: {
          all: true,
          a: 3,
          time: Time.new(2017,10, 10, 12),
        }, event_id: "011cc5c4-d638-4785-9aa0-7d6a2d3e2a58"))

        client.append_to_stream(EventA1.new(data: {
            a1: true,
            decimal: BigDecimal.new("20.00"),
          }, event_id: "d39cb65f-bc3c-4fbb-9470-52bf5e322bba"),
          stream_name: "Order-1",
        )
        client.append_to_stream(EventA2.new(data: {
            all: true,
            symbol: :symbol,
          }, event_id: "f2cecc51-adb1-4d83-b3ca-483d26311f03"),
          stream_name: "Order-1",
        )
        client.append_to_stream(EventA1.new(data: {
            all: true,
            symbol: :symbol,
          }, event_id: "600e1e1b-7fdf-44e2-a406-8b612c67c881"),
          stream_name: "Order-1",
        )

        client.append_to_stream(EventB1.new(data: {
          a1: true,
          decimal: BigDecimal.new("20.00"),
        }, event_id: "9009df88-6044-4a62-b7ae-098c42a9c5e1"),
          stream_name: "WroclawBuyers",
        )
        client.append_to_stream(EventB2.new(data: {
          all: true,
          symbol: :symbol,
        }, event_id: "cefdd213-0c92-46f6-bbdf-3ea9542d969a"),
          stream_name: "WroclawBuyers",
        )
        client.append_to_stream(EventB2.new(data: {
          all: true,
          symbol: :symbol,
        }, event_id: "36775fcd-c5d8-49c9-bf70-f460ba12d7c2"),
          stream_name: "WroclawBuyers",
        )

        puts "filled" if $verbose
      EOF

      run_the_migration
      reset_columns_information
      verify_all_events_stream
      verify_event_sourced_stream
      verify_technical_stream
      compare_new_schema
    ensure
      drop_database
    end
  end

  private

  def repository
    @repository ||= RailsEventStoreActiveRecord::EventRepository.new
  end

  def mapper
    RubyEventStore::Mappers::NullMapper.new
  end

  def specification
    @specification ||= RubyEventStore::Specification.new(
      RubyEventStore::SpecificationReader.new(repository, mapper)
    )
  end

  def run_the_migration
    code = Migrator.new(File.expand_path("../lib/rails_event_store_active_record/legacy/generators/templates", __dir__))
      .send(:migration_code, 'migrate_res_schema_v1_to_v2')
    eval(code)
    MigrateResSchemaV1ToV2.class_eval do
      def preserve_positions?(stream_name)
        stream_name == "Order-1"
      end
    end
    MigrateResSchemaV1ToV2.new.up
  end

  def reset_columns_information
    RailsEventStoreActiveRecord::Event.reset_column_information
    RailsEventStoreActiveRecord::EventInStream.reset_column_information
  end

  def verify_all_events_stream
    events = repository.read(specification.from(:head).limit(100).result)
    expect(events.size).to eq(9)
    expect(events.map(&:event_id)).to eq(%w(
      94b297a3-5a29-4942-9038-3efeceb4d905
      6a31b594-7d8f-428b-916f-496f6da05bfd
      011cc5c4-d638-4785-9aa0-7d6a2d3e2a58
      d39cb65f-bc3c-4fbb-9470-52bf5e322bba
      f2cecc51-adb1-4d83-b3ca-483d26311f03
      600e1e1b-7fdf-44e2-a406-8b612c67c881
      9009df88-6044-4a62-b7ae-098c42a9c5e1
      cefdd213-0c92-46f6-bbdf-3ea9542d969a
      36775fcd-c5d8-49c9-bf70-f460ba12d7c2
    ))
    positions = RailsEventStoreActiveRecord::EventInStream.
      where(stream: "all").
      order("position ASC").
      to_a.
      map(&:position).uniq
    expect(positions).to eq([nil])
  end

  def verify_event_sourced_stream
    events = repository.read(specification.stream("Order-1").result)

    expect(events.map(&:event_id)).to eq(%w(
      d39cb65f-bc3c-4fbb-9470-52bf5e322bba
      f2cecc51-adb1-4d83-b3ca-483d26311f03
      600e1e1b-7fdf-44e2-a406-8b612c67c881
    ))
    positions = RailsEventStoreActiveRecord::EventInStream.
      where(stream: "Order-1").
      order("position ASC").
      to_a.
      map(&:position)
    expect(positions).to eq([0, 1, 2])
    expect do
      repository.append_to_stream(RubyEventStore::SRecord.new(event_id: "7c485b58-2d6a-4017-a174-8ab41ea4a4dd"),
        RubyEventStore::Stream.new("Order-1"),
        RubyEventStore::ExpectedVersion.new(1)
      )
    end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
    repository.append_to_stream(RubyEventStore::SRecord.new(event_id: "3cf767d5-16ad-43a7-8d65-bb5575b301f2"),
      RubyEventStore::Stream.new("Order-1"),
      RubyEventStore::ExpectedVersion.new(2)
    )
  end

  def verify_technical_stream
    events = repository.read(specification.stream("WroclawBuyers").result)
    expect(events.map(&:event_id)).to eq(%w(
      9009df88-6044-4a62-b7ae-098c42a9c5e1
      cefdd213-0c92-46f6-bbdf-3ea9542d969a
      36775fcd-c5d8-49c9-bf70-f460ba12d7c2
    ))
    positions = RailsEventStoreActiveRecord::EventInStream.
      where(stream: "WroclawBuyers").
      order("position ASC").
      to_a.
      map(&:position).
      uniq
    expect(positions).to eq([nil])
  end

  def drop_existing_tables_to_clean_state
    drop_database
  end

  def dump_current_schema
    @schema = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, @schema)
    @schema.rewind
    @schema = @schema.read
  end

  def compare_new_schema
    schema = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, schema)
    schema.rewind
    schema = schema.read
    expect(schema).to eq(@schema)
  end
end
