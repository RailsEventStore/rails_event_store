# frozen_string_literal: true

require_relative "../../../support/helpers/rspec_defaults"
require "ruby_event_store"
require "ruby_event_store/browser/app"
require "ruby_event_store/browser/swimlane"
require "rack"

DummyEvent = Class.new(::RubyEventStore::Event)
