# frozen_string_literal: true

require 'active_record'

module RubyEventStore
  module Outbox
    class Record < ::ActiveRecord::Base
      self.primary_key = :id
      self.table_name = 'event_store_outbox'

      def hash_payload
        JSON.parse(payload).deep_symbolize_keys
      end
    end
  end
end
