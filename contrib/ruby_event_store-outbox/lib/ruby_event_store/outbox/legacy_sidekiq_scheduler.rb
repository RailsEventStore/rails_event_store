# frozen_string_literal: true

require_relative "sidekiq_producer"

module RubyEventStore
  module Outbox
    class LegacySidekiqScheduler
      def initialize
        @sidekiq_producer = SidekiqProducer.new
      end

      def call(klass, serialized_record)
        sidekiq_producer.call(klass, [serialized_record])
      end

      def verify(subscriber)
        Class === subscriber && subscriber.respond_to?(:through_outbox?) && subscriber.through_outbox?
      end

      private
      attr_reader :sidekiq_producer
    end
  end
end
