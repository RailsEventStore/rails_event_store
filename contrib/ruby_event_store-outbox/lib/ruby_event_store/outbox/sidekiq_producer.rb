# frozen_string_literal: true

require 'sidekiq'
require "ruby_event_store/outbox/sidekiq5_format"

module RubyEventStore
  module Outbox
    class SidekiqProducer
      def call(klass, args)
        sidekiq_client = Sidekiq::Client.new(Sidekiq.redis_pool)
        item = {
          'class' => klass,
          'args' => args,
        }
        normalized_item = sidekiq_client.__send__(:normalize_item, item)
        payload = sidekiq_client.__send__(:process_single, normalized_item.fetch('class'), normalized_item)
        if payload
          Record.create!(
            format: SIDEKIQ5_FORMAT,
            split_key: payload.fetch('queue'),
            payload: payload.to_json
          )
        end
      end
    end
  end
end
