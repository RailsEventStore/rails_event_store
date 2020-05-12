require 'active_record'
require 'rails_event_store_active_record'

module ConnectedActiveRecord
  class Repository
    def initialize(writing: nil, reading: nil)
      @repository = RailsEventStoreActiveRecord::EventRepository.new(
        build_base_klass(writing, reading)
      )
    end

    def append_to_stream(events, stream, expected_version)
      repository.append_to_stream(events, stream, expected_version)
    end

    def link_to_stream(event_ids, stream, expected_version)
      repository.link_to_stream(event_ids, stream, expected_version)
    end

    def delete_stream(stream)
      repository.delete_stream(stream)
    end

    def has_event?(event_id)
      repository.has_event?(event_id)
    end

    def last_stream_event(stream)
      repository.last_stream_event(stream)
    end

    def read(specification)
      repository.read(specification)
    end

    def count(specification)
      repository.count(specification)
    end

    def update_messages(messages)
      repository.update_messages(messages)
    end

    def streams_of(event_id)
      repository.streams_of(event_id)
    end

    private
    attr_reader :repository

    def build_base_klass(writing, reading)
      return ActiveRecord::Base if writing.nil? && reading.nil?
      Class.new(ActiveRecord::Base) do
        self.abstract_class = true
        connects_to database: { writing: writing, reading: reading }
      end
    end
  end
end
