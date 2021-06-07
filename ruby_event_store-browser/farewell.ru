require "bundler/inline"

gemfile do
  gem "ruby_event_store",                path: "../ruby_event_store"
  gem "ruby_event_store-browser",        path: "."
  gem "rails_event_store_active_record", path: "../rails_event_store_active_record"
  gem "pg"
end

require "ruby_event_store"
require "ruby_event_store/browser/app"
require "rails_event_store_active_record"

event_store = lambda do
  ActiveRecord::Base.establish_connection(ENV.fetch("DATABASE_URL"))

  RubyEventStore::Client.new(
    repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL)
  )
end

run RubyEventStore::Browser::App.for(event_store_locator: event_store)
