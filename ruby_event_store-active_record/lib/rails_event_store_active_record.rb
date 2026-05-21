# frozen_string_literal: true

require "ruby_event_store/active_record"
require "ruby_event_store/deprecations"

RubyEventStore::Deprecations.register(
  :rails_event_store_active_record_renamed,
  "The 'rails_event_store_active_record' gem has been renamed.\n" \
    "Please use 'ruby_event_store-active_record' in your Gemfile instead.",
)

RubyEventStore::Deprecations.warn(:rails_event_store_active_record_renamed)

RailsEventStoreActiveRecord = RubyEventStore::ActiveRecord unless defined?(RailsEventStoreActiveRecord)
