require "spec_helper"
require "uri"

class MyEvent < RubyEventStore::Event
end

RSpec.describe DresClient do
  it "has a version number" do
    expect(DresClient::VERSION).not_to be nil
  end

  it "gets events" do
    stub_request(:get, "http://example.org/dres_rails").to_return(
      body: File.read("../shared_spec/body1.json")
    )
    client = DresClient::Http.new(
      mapper: RubyEventStore::Mappers::Default.new,
      uri: URI("http://example.org/dres_rails")
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

end