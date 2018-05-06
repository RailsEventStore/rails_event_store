require 'rails/generators' # doh
require 'rails_event_store_active_record'
require 'ruby_event_store'
require 'logger'

$verbose = ENV.has_key?('VERBOSE') ? true : false

ActiveRecord::Base.logger = Logger.new(STDOUT) if $verbose
ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'].gsub("db.sqlite3", "../../db.sqlite3"))
ActiveRecord::Schema.define do
  self.verbose = $verbose
  create_table(:event_store_events, force: false) do |t|
    t.string      :stream,      null: false
    t.string      :event_type,  null: false
    t.string      :event_id,    null: false
    t.text        :metadata
    t.text        :data,        null: false
    t.datetime    :created_at,  null: false
  end
  add_index :event_store_events, :stream
  add_index :event_store_events, :created_at
  add_index :event_store_events, :event_type
  add_index :event_store_events, :event_id, unique: true
end

class EventAll < RubyEventStore::Event
end
class EventA1 < RubyEventStore::Event
end
class EventA2 < RubyEventStore::Event
end
class EventB1 < RubyEventStore::Event
end
class EventB2 < RubyEventStore::Event
end

client = RubyEventStore::Client.new(
  repository: RailsEventStoreActiveRecord::EventRepository.new
)
client.append_to_stream(EventAll.new(data: {
  all: true,
  a: 1,
  text: "text",
}, event_id: "94b297a3-5a29-4942-9038-3efeceb4d905"))
client.append_to_stream(EventAll.new(data: {
  all: true,
  a: 2,
  date: Date.new(2017, 10, 11),
}, event_id: "6a31b594-7d8f-428b-916f-496f6da05bfd"))
client.append_to_stream(EventAll.new(data: {
  all: true,
  a: 3,
  time: Time.new(2017,10, 10, 12),
}, event_id: "011cc5c4-d638-4785-9aa0-7d6a2d3e2a58"))



client.append_to_stream(EventA1.new(data: {
    a1: true,
    decimal: BigDecimal.new("20.00"),
  }, event_id: "d39cb65f-bc3c-4fbb-9470-52bf5e322bba"),
  stream_name: "Order-1",
)
client.append_to_stream(EventA2.new(data: {
    all: true,
    symbol: :symbol,
  }, event_id: "f2cecc51-adb1-4d83-b3ca-483d26311f03"),
  stream_name: "Order-1",
)
client.append_to_stream(EventA1.new(data: {
    all: true,
    symbol: :symbol,
  }, event_id: "600e1e1b-7fdf-44e2-a406-8b612c67c881"),
  stream_name: "Order-1",
)


client.append_to_stream(EventB1.new(data: {
  a1: true,
  decimal: BigDecimal.new("20.00"),
}, event_id: "9009df88-6044-4a62-b7ae-098c42a9c5e1"),
  stream_name: "WroclawBuyers",
)
client.append_to_stream(EventB2.new(data: {
  all: true,
  symbol: :symbol,
}, event_id: "cefdd213-0c92-46f6-bbdf-3ea9542d969a"),
  stream_name: "WroclawBuyers",
)
client.append_to_stream(EventB2.new(data: {
  all: true,
  symbol: :symbol,
}, event_id: "36775fcd-c5d8-49c9-bf70-f460ba12d7c2"),
  stream_name: "WroclawBuyers",
)

puts "filled" if $verbose
