require 'ruby_event_store'
require 'ruby_event_store/protobuf'
require_relative 'mappers/events_pb'
require_relative '../../../ruby_event_store/spec/support/correlatable'
require_relative '../../../support/helpers/protobuf_helper'
require_relative '../../../support/helpers/rspec_defaults'

TestEvent = Class.new(RubyEventStore::Event)

module TimeEnrichment
  def with(event, timestamp: Time.now.utc, valid_at: nil)
    event.metadata[:timestamp] ||= timestamp
    event.metadata[:valid_at]  ||= valid_at || timestamp
    event
  end
  module_function :with
end
