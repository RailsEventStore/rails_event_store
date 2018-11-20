require 'spec_helper'

RSpec.describe "JSON serializer" do
  include Rack::Test::Methods

  it "should handle metadata timestamp" do
    dummy_event = DummyEvent.new
    event_store.publish(dummy_event, stream_name: "dummy")
    get "/streams/all"
    expect(last_response).to be_ok

    metadata = JSON.parse(last_response.body)["data"][0]["attributes"]["metadata"]
    expect(metadata["timestamp"]).to eq(skip_fractional(dummy_event.metadata[:timestamp]).iso8601(3))
  end

  def skip_fractional(time)
    Time.utc(time.year, time.month, time.day, time.hour, time.min, time.sec)
  end

  let(:event_store) do
    RubyEventStore::Client.new(
      repository: RubyEventStore::InMemoryRepository.new,
      mapper: RubyEventStore::Mappers::Default.new(serializer: JSON)
    )
  end
  let(:app) { APP_BUILDER.call(event_store) }
end