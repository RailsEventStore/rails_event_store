# frozen_string_literal: true

require "ruby_event_store"
require "ruby_event_store/active_record"
require "active_record"
require "active_support/notifications"

require_relative "scavenger/version"
require_relative "scavenger/status"
require_relative "scavenger/state"
require_relative "scavenger/lock"
require_relative "scavenger/runner"
require_relative "scavenger/migration_generator"
require_relative "scavenger/cli"
require_relative "scavenger/railtie" if defined?(Rails::Railtie)
