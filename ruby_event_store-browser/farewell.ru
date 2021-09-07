require "bundler/inline"

RES_VERSION = "2.0.1"

gemfile do
  gem "ruby_event_store",                RES_VERSION
  gem "ruby_event_store-browser",        RES_VERSION
  gem "rails_event_store_active_record", RES_VERSION
  gem "pg"
  gem "mysql2"
  gem "sqlite3"
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
