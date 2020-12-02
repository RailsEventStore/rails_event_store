# frozen_string_literal: true

require 'yaml'

module RubyEventStore
  module Mappers
    module Transformation
      class Serialization
        def initialize(serializer: YAML)
          warn <<~EOW
            #{self.class} has been deprecated and is effectively no-op. You should remove this transformation from your pipeline.

            Instead, pass the serializer directly to the repository and the scheduler. For example:

            Rails.configuration.event_store = RailsEventStore::Client.new(
              mapper:     RubyEventStore::Mappers::Default.new,
              repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: #{serializer}),
              dispatcher: RubyEventStore::ComposedDispatcher.new(
                RubyEventStore::ImmediateAsyncDispatcher.new(scheduler: ActiveJobScheduler.new(serializer: #{serializer}),
                RubyEventStore::Dispatcher.new
              )
            )
          EOW
        end

        def dump(item)
          item
        end

        def load(item)
          item
        end
      end
    end
  end
end
