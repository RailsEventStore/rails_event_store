begin
  require 'mongoid'
rescue LoadError
end

require 'rails_event_store/models/mongoid'
require 'rails_event_store/event_entity'

module RailsEventStore
  module Repositories
    module Mongoid
      class EventRepository

        def initialize(adapter = ::RailsEventStore::Models::Mongoid::Event)
          @adapter = adapter
        end
        attr_reader :adapter

        def find(condition)
          build_event_entity adapter.where(condition).first
        end

        def create(data)
          build_event_entity adapter.create(data)
        rescue Moped::Errors::OperationFailure
          raise EventCannotBeSaved
        end

        def delete(condition)
          adapter.destroy_all condition
          nil
        end

        def get_all_events
          adapter.all.asc(:stream).map &method(:build_event_entity)
        end

        def last_stream_event(stream_name)
          adapter.where(stream: stream_name).last.map &method(:build_event_entity)
        end

        def load_all_events_forward(stream_name)
          adapter.where(stream: stream_name).asc(:_id).map &method(:build_event_entity)
        end

        def load_events_batch(stream_name, start_point, count)
          adapter.where(stream: stream_name).asc(:_id).offset(start_point).limit(count).map &method(:build_event_entity)
        end

        private

        def build_event_entity(record)
          ::RailsEventStore::EventEntity.new(
            id:         record.id,
            stream:     record.stream,
            event_type: record.event_type,
            event_id:   record.event_id,
            metadata:   record.metadata,
            data:       record.data,
            created_at: record.created_at
          )
        end

      end
    end
  end
end
