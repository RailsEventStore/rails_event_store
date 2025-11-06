# frozen_string_literal: true

RSpec.shared_examples :event_types_query do |query_class|
  specify "responds to call" do
    event_store = RubyEventStore::Client.new
    query = query_class.new(event_store)

    expect(query).to respond_to(:call)
  end

  specify "returns array of EventType objects" do
    event_store = RubyEventStore::Client.new
    query = query_class.new(event_store)

    result = query.call

    expect(result).to be_an(Array)
    result.each do |event_type|
      expect(event_type).to be_a(RubyEventStore::Browser::EventTypesQuerying::EventType)
      expect(event_type.event_type).to be_a(String)
      expect(event_type.stream_name).to be_a(String)
    end
  end

  specify "can be initialized with event_store" do
    event_store = RubyEventStore::Client.new

    expect { query_class.new(event_store) }.not_to raise_error
  end
end
