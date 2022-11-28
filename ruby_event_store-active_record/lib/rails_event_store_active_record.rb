require "ruby_event_store-active_record/lib/ruby_event_store-active_record"

warn <<~EOW
  The 'rails_event_store_active_record' gem has been renamed.

  Please change your Gemfile or gemspec
  to reflect its new name:

    'ruby_event_store-active_record'

EOW

RailsEventStoreActiveRecord = RubyEventStore::ActiveRecord
