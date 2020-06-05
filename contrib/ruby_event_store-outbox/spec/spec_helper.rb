require 'ruby_event_store'
require "ruby_event_store/outbox"
require_relative '../../../support/helpers/rspec_defaults'
require_relative '../../../support/helpers/mutant_timeout'
require_relative '../../../support/helpers/schema_helper'
require 'rails'

module TimestampEnrichment
  def with_timestamp(event, timestamp = Time.now.utc)
    event.metadata[:timestamp] ||= timestamp
    event
  end
  module_function :with_timestamp
end

$verbose = ENV.has_key?('VERBOSE') ? true : false
ActiveRecord::Schema.verbose = $verbose

ENV['DATABASE_URL'] ||= 'sqlite3:db.sqlite3'
