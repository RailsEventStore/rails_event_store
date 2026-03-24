# frozen_string_literal: true

module RubyEventStore
  module CLI
    module EventStoreResolver
      DEFAULT_REQUIRE_PATH = "config/environment.rb"
      CANDIDATE_CONSTS = %w[EVENT_STORE RES EventStore].freeze

      class << self
        attr_accessor :event_store
      end

      def self.resolve
        return event_store if event_store

        require File.expand_path(DEFAULT_REQUIRE_PATH)
        find_event_store || abort(<<~MSG)
          Could not find event store instance after loading #{DEFAULT_REQUIRE_PATH}.

          Expected one of:
            - Rails.configuration.event_store  (standard RES setup)
            - A constant named: #{CANDIDATE_CONSTS.join(", ")}

          Or configure it explicitly in an initializer:
            RubyEventStore::CLI.configure { |c| c.event_store = MyApp::EventStore }
        MSG
      end

      def self.find_event_store
        if defined?(Rails) && Rails.respond_to?(:configuration) &&
            Rails.configuration.respond_to?(:event_store)
          return Rails.configuration.event_store
        end

        CANDIDATE_CONSTS.each do |const_name|
          return Object.const_get(const_name) if Object.const_defined?(const_name)
        end

        nil
      end
    end
  end
end
