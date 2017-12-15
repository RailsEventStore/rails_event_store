require 'spec_helper'

DummyEvent = Class.new(::RailsEventStore::Event)

module RailsEventStore
  RSpec.describe Browser, type: :request do
    specify do
      get '/res'
      expect(response).to be_successful
    end

    specify do
      event_store.publish_event(
        DummyEvent.new(data: { foo: 1, bar: 2, baz: 3 }),
        stream_name: 'dummy'
      )

      get '/res/streams'
      expect(response.body).to eq(JSON.dump([{ name: "all" }, { name: "dummy" }]))
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end