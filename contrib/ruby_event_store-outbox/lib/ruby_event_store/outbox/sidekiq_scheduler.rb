# frozen_string_literal: true

require 'sidekiq'

module RubyEventStore
  module Outbox
    class SidekiqScheduler
      SIDEKIQ5_FORMAT = "sidekiq5"

      def call(klass, serialized_event)
        sidekiq_client = Sidekiq::Client.new(Sidekiq.redis_pool)
        item = {
          'class' => klass,
          'args' => [serialized_event.to_h],
        }
        normalized_item = sidekiq_client.send(:normalize_item, item)
        payload = sidekiq_client.send(:process_single, normalized_item['class'], normalized_item)
        if payload
          Record.create!(
            format: SIDEKIQ5_FORMAT,
            split_key: payload['queue'],
            payload: payload.to_json
          )
        end
      end

      def verify(subscriber)
        Class === subscriber && subscriber.respond_to?(:through_outbox?) && subscriber.through_outbox?
      end
    end
  end
end
