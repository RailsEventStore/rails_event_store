# frozen_string_literal: true

require_relative "sidekiq_producer"

module RubyEventStore
  module Outbox
    class SidekiqScheduler
      def initialize(repository: Repositories::Mysql57.build_for_producer, serializer: RubyEventStore::Serializers::YAML)
        @serializer = serializer
        @sidekiq_producer = SidekiqProducer.new(repository)
      end

      def call(klass, record)
        sidekiq_producer.call(klass, [record.serialize(serializer)])
      end

      def verify(subscriber)
        Class === subscriber && subscriber.respond_to?(:through_outbox?) && subscriber.through_outbox?
      end

      private

      attr_reader :serializer, :sidekiq_producer
    end
  end
end
