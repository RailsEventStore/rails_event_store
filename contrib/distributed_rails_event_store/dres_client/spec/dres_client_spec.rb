require "spec_helper"
require "uri"

class MyEvent < RubyEventStore::Event
end

RSpec.describe DresClient do
  it "gets events" do
    stub_request(:get, "http://example.org/dres_rails").to_return(
      body: File.read("../shared_spec/body1.json")
    )
    client = DresClient::Http.new(
      mapper: RubyEventStore::Mappers::Default.new,
      uri: URI("http://example.org/dres_rails"),
      api_key: "haXXy"
    )
    events = client.events(after_event_id: nil)
    expect(events).to eq([
      MyEvent.new(
        data: {one: 1},
        event_id: "dfc7f58d-aae3-4d21-8f3a-957bfa765ef8",
      ),
      MyEvent.new(
        data: {two: 2},
        event_id:"b2f58e9c-0887-4fbf-99a8-0bb19cfebeef",
      ),
    ])
  end

  it "drains events until empty" do
    stub_request(:get, "http://example.org/dres_rails").to_return(
      body: File.read("../shared_spec/body1.json")
    )
    stub_request(:get, "http://example.org/dres_rails?after_event_id=b2f58e9c-0887-4fbf-99a8-0bb19cfebeef").to_return(
      body: File.read("../shared_spec/body2.json")
    )
    stub_request(:get, "http://example.org/dres_rails?after_event_id=0d29084e-ad75-4e3a-8e63-5c894c540b8d").to_return(
      body: File.read("../shared_spec/body3.json")
    )
    client = DresClient::Http.new(
      mapper: RubyEventStore::Mappers::Default.new,
      uri: URI("http://example.org/dres_rails"),
      api_key: "haXXy"
    )
    expect do |collector|
      client.drain(after_event_id: nil, &collector)
    end.to yield_successive_args(
      [
        MyEvent.new(
          data: {one: 1},
          event_id: "dfc7f58d-aae3-4d21-8f3a-957bfa765ef8",
        ),
        MyEvent.new(
          data: {two: 2},
          event_id:"b2f58e9c-0887-4fbf-99a8-0bb19cfebeef",
        ),
      ], [
        MyEvent.new(
          data: {three: 3},
          event_id: "d1f7bd58-ff2b-45d8-8a1d-6ea00d8c3dc3",
        ),
        MyEvent.new(
          data: {four: 4},
          event_id:"0d29084e-ad75-4e3a-8e63-5c894c540b8d",
        ),
      ]
    )
  end

  it "queries events constantly in a loop" do
    stub_request(:get, "http://example.org/dres_rails").to_return(
      body: File.read("../shared_spec/body1.json")
    )
    stub_request(:get, "http://example.org/dres_rails?after_event_id=b2f58e9c-0887-4fbf-99a8-0bb19cfebeef").to_return(
      body: File.read("../shared_spec/body2.json")
    )
    stub_request(:get, "http://example.org/dres_rails?after_event_id=0d29084e-ad75-4e3a-8e63-5c894c540b8d").to_return(
      body: File.read("../shared_spec/body3.json")
    )
    client = DresClient::Http.new(
      mapper: RubyEventStore::Mappers::Default.new,
      uri: URI("http://example.org/dres_rails"),
      api_key: "haXXy"
    )
    expect do |collector|
      empty = 0
      client.run(after_event_id: nil) do |events|
        collector.to_proc.call(events)
        empty += 1 if events.empty?
        break if empty == 3
      end
    end.to yield_successive_args(
      [
        MyEvent.new(
          data: {one: 1},
          event_id: "dfc7f58d-aae3-4d21-8f3a-957bfa765ef8",
        ),
        MyEvent.new(
          data: {two: 2},
          event_id:"b2f58e9c-0887-4fbf-99a8-0bb19cfebeef",
        ),
      ], [
      MyEvent.new(
        data: {three: 3},
        event_id: "d1f7bd58-ff2b-45d8-8a1d-6ea00d8c3dc3",
      ),
      MyEvent.new(
        data: {four: 4},
        event_id:"0d29084e-ad75-4e3a-8e63-5c894c540b8d",
      ),
    ], [], [], []
    )
  end

end