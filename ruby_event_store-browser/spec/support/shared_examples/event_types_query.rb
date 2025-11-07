# frozen_string_literal: true

RSpec.shared_examples :event_types_query do |query|
  specify "responds to call" do
    expect(query).to respond_to(:call)
  end

  specify "returns array of EventType objects" do
    result = query.call

    expect(result).to be_an(Array)
    expect(result.size).to be > 1
    result.each do |event_type|
      expect(event_type).to be_a(RubyEventStore::Browser::EventTypesQuerying::EventType)
      expect(event_type.event_type).to be_a(String)
      expect(event_type.stream_name).to be_a(String)
    end
  end
end
