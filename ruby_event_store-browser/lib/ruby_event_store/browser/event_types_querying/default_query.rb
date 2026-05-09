# frozen_string_literal: true

module RubyEventStore
  module Browser
    module EventTypesQuerying
      class DefaultQuery
        def initialize(event_store); end

        def call
          all_event_subclasses(RubyEventStore::Event)
            .select { |klass| !klass.name.nil? }
            .sort_by(&:name)
            .uniq(&:name)
            .map { |klass| EventType.new(event_type: klass.name, stream_name: "$by_type_#{klass.name}") }
        end

        private

        def all_event_subclasses(klass)
          klass.subclasses + klass.subclasses.flat_map { |subclass| all_event_subclasses(subclass) }
        end
      end
    end
  end
end
