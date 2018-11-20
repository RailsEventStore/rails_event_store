require 'spec_helper'

RSpec.describe "JSON serializer" do
  include Rack::Test::Methods

  it "should handle metadata timestamp" do
    dummy_event = DummyEvent.new
    event_store.publish(dummy_event, stream_name: "dummy")
    get "/streams/all"
    expect(last_response).to be_ok

    metadata = JSON.parse(last_response.body)["data"][0]["attributes"]["metadata"]
    expect(metadata["timestamp"]).to eq(dummy_event.metadata[:timestamp].iso8601(3))
  end

  let(:event_store) do
    RubyEventStore::Client.new(
      repository: RubyEventStore::InMemoryRepository.new,
      mapper: RubyEventStore::Mappers::Default.new(serializer: JSON)
    )
  end
  let(:app) { APP_BUILDER.call(event_store) }
end