# frozen_string_literal: true

module RubyEventStore
  module Browser
    module EventTypesQuerying
      class DefaultQuery
        def initialize(event_store)
          @event_store = event_store
        end

        def call
          event_classes = []

          ObjectSpace.each_object(Class) do |klass|
            event_classes << klass if klass < RubyEventStore::Event && !klass.name.nil?
          end

          event_classes.sort_by(&:name).uniq(&:name).map do |klass|
            EventType.new(event_type: klass.name, stream_name: "$by_type_#{klass.name}")
          end
        end

        private

        attr_reader :event_store
      end
    end
  end
end
