# frozen_string_literal: true

require 'yaml'

module RubyEventStore
  module Mappers
    class Default < PipelineMapper
      UNSET = Object.new.freeze

      attr_reader :serializer

      def initialize(serializer: UNSET, events_class_remapping: {})
        case serializer
        when UNSET
          @serializer = YAML
        else
          warn <<~EOW
            Passing serializer: to #{self.class} has been deprecated. 

            Pass it directly to the repository and the scheduler. For example:

            Rails.configuration.event_store = RailsEventStore::Client.new(
              mapper:     RubyEventStore::Mappers::Default.new,
              repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: YAML),
              dispatcher: RubyEventStore::ComposedDispatcher.new(
                RubyEventStore::ImmediateAsyncDispatcher.new(scheduler: ActiveJobScheduler.new(serializer: YAML),
                RubyEventStore::Dispatcher.new
              )
            )
          EOW
          @serializer = serializer
        end

        super(Pipeline.new(
          Transformation::EventClassRemapper.new(events_class_remapping),
          Transformation::SymbolizeMetadataKeys.new,
        ))
      end
    end
  end
end
