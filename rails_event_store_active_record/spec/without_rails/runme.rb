require 'active_record'
require 'rails_event_store_active_record'
require 'ruby_event_store'
require 'logger'

$verbose = ENV.has_key?('VERBOSE') ? true : false

ActiveRecord::Base.logger = Logger.new(STDOUT) if $verbose

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'].gsub("db.sqlite3", "../../db.sqlite3"))

class EventA1 < RubyEventStore::Event
end

client = RubyEventStore::Client.new(
  repository: RailsEventStoreActiveRecord::EventRepository.new
)
client.append(EventA1.new(data: {
    a1: true,
    decimal: BigDecimal.new("20.00"),
  }, event_id: "d39cb65f-bc3c-4fbb-9470-52bf5e322bba"),
  stream_name: "Order-1",
)
puts "filled" if $verbose