# frozen_string_literal: true

require "ruby_event_store/active_record"

warn <<~EOW
  The 'rails_event_store_active_record' gem has been renamed and is deprecated.
  Please change your Gemfile or gemspec to use 'ruby_event_store-active_record' instead.
EOW

RailsEventStoreActiveRecord = RubyEventStore::ActiveRecord
