# frozen_string_literal: true

require_relative '../../../support/helpers/rspec_defaults'
require "ruby_event_store/flipper"
require "ruby_event_store/rspec"
require_relative '../lib/generators/ruby_event_store/flipper/templates/events.rb'
require "ruby_event_store"
require "active_support/notifications"
require "flipper"
