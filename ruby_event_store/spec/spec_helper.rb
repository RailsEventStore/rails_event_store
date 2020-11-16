require 'ruby_event_store'
require_relative '../../support/helpers/rspec_defaults'
require_relative '../../support/helpers/protobuf_helper'
require 'support/correlatable'

OrderCreated = Class.new(RubyEventStore::Event)
ProductAdded = Class.new(RubyEventStore::Event)
TestEvent = Class.new(RubyEventStore::Event)

module TimeEnrichment
  def with(event, timestamp: Time.now.utc, valid_at: nil)
    event.metadata[:timestamp] ||= timestamp
    event.metadata[:valid_at]  ||= valid_at || timestamp
    event
  end
  module_function :with
end

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

RSpec::Matchers.define :contains_ids do |expected_ids|
  match do |enum|
    @actual = enum.map(&:event_id)
    values_match?(expected_ids, @actual)
  end
  diffable
end
