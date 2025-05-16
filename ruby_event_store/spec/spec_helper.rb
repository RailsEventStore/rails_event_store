# frozen_string_literal: true

require "ruby_event_store"
require_relative "../../support/helpers/rspec_defaults"
require_relative "../../support/helpers/time_enrichment"
require "support/correlatable"

module RubyEventStore
  class SpecHelper
    def supports_concurrent_auto?
      true
    end

    def supports_concurrent_any?
      true
    end

    def supports_binary?
      ENV["DATA_TYPE"] == "binary"
    end

    def supports_upsert?
      true
    end

    def supports_position_queries?
      true
    end

    def supports_event_in_stream_query?
      true
    end

    def has_connection_pooling?
      false
    end

    def connection_pool_size
    end
  end
end

OrderCreated = Class.new(RubyEventStore::Event)
ProductAdded = Class.new(RubyEventStore::Event)
TestEvent = Class.new(RubyEventStore::Event)

module Subscribers
  class InvalidHandler
  end

  class ValidHandler
    def initialize
      @handled_events = []
    end
    attr_reader :handled_events

    def call(event)
      @handled_events << event
    end
  end
end

class ReverseYamlSerializer
  def self.load(value)
    YAML.load(value.reverse)
  end

  def self.dump(value)
    YAML.dump(value).reverse
  end
end

class ScheduledWithSerialization
  def initialize(serializer:)
    @serializer = serializer
  end

  def call(subscriber, record)
    subscriber.call(record.serialize(@serializer))
  end

  def verify(subscriber)
    subscriber.respond_to?(:call)
  end
end

::RSpec::Matchers.define :contains_ids do |expected_ids|
  match do |enum|
    @actual = enum.map(&:event_id)
    values_match?(expected_ids, @actual)
  end
  diffable
end
