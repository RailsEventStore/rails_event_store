# frozen_string_literal: true

require "ruby_event_store"
require "rom"
require "rom/sql"
require "rom/transformer"

require_relative "rom/changesets/create_events"
require_relative "rom/changesets/create_stream_entries"
require_relative "rom/changesets/update_events"
require_relative "rom/event_repository"
require_relative "rom/index_violation_detector"
require_relative "rom/mappers/event_to_serialized_record"
require_relative "rom/mappers/stream_entry_to_serialized_record"
require_relative "rom/relations/events"
require_relative "rom/relations/stream_entries"
require_relative "rom/repositories/events"
require_relative "rom/repositories/stream_entries"
require_relative "rom/types"
require_relative "rom/unit_of_work"

module RubyEventStore
  module ROM
    class << self
      def setup(adapter_name, database_uri = ENV["DATABASE_URL"])
        rom_container(adapter_name, database_uri) do |rom|
          rom.register_mapper Mappers::StreamEntryToSerializedRecord
          rom.register_mapper Mappers::EventToSerializedRecord
          rom.register_relation Relations::Events
          rom.register_relation Relations::StreamEntries
        end
      end

      def rom_container(adapter_name, database_uri, &block)
        if adapter_name.is_a?(::ROM::Configuration)
          ::ROM.container(adapter_name.tap(&block), &block)
        else
          ::ROM.container(adapter_name, database_uri, &block)
        end
      end
    end
  end
end
