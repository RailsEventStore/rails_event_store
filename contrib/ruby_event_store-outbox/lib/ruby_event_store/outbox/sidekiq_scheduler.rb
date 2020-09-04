# frozen_string_literal: true

require "ruby_event_store/outbox/sidekiq_producer"

module RubyEventStore
  module Outbox
    class SidekiqScheduler
      def initialize
        @sidekiq_producer = SidekiqProducer.new
      end

      def call(klass, serialized_record)
        sidekiq_producer.call(klass, [serialized_record.to_h])
      end

      def verify(subscriber)
        Class === subscriber && subscriber.respond_to?(:through_outbox?) && subscriber.through_outbox?
      end

      private
      attr_reader :sidekiq_producer
    end
  end
end
