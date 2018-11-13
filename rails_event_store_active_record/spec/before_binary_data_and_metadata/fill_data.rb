require 'rails/generators' # doh
require 'rails_event_store_active_record'
require 'ruby_event_store'
require 'logger'
require_relative '../../../lib/migrator'

$verbose = ENV.has_key?('VERBOSE') ? true : false
ActiveRecord::Schema.verbose = $verbose
ActiveRecord::Base.logger = Logger.new(STDOUT) if $verbose
ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'].gsub("db.sqlite3", "../../db.sqlite3"))


gem_path = $LOAD_PATH.find { |path| path.match(/rails_event_store_active_record/) }
Migrator.new(File.expand_path('rails_event_store_active_record/generators/templates', gem_path))
  .run_migration('create_event_store_events', 'migration')

EventAll = Class.new(RubyEventStore::Event)

client = RubyEventStore::Client.new(repository: RailsEventStoreActiveRecord::EventRepository.new)
client.append(
  EventAll.new(
    event_id: "94b297a3-5a29-4942-9038-3efeceb4d905",
    data: {
      all: true,
      a: 1,
      text: "text",
    }
  )
)

puts "filled" if $verbose
