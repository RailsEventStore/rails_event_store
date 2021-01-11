require 'ruby_event_store'
require 'ruby_event_store/protobuf'
require_relative 'mappers/events_pb'
require_relative '../../../ruby_event_store/spec/support/correlatable'
require_relative '../../../support/helpers/protobuf_helper'
require_relative '../../../support/helpers/rspec_defaults'
require_relative '../../../support/helpers/time_enrichment'

TestEvent = Class.new(RubyEventStore::Event)
