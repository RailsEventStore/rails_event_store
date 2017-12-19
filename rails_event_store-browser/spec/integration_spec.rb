require 'spec_helper'
require 'active_support/core_ext/hash/keys'

DummyEvent = Class.new(::RailsEventStore::Event)

module RailsEventStore
  RSpec.describe Browser, type: :request do
    specify do
      get '/res'
      expect(response).to be_successful
    end

    specify do
      event_store.publish_event(DummyEvent.new, stream_name: 'dummy')
      get '/res/streams'

      expect(response.body).to be_collection([all_stream, dummy_stream])
    end

    specify do
      dummy_event =
        DummyEvent.new(data: {
          foo: 1,
          bar: 2.0,
          baz: "3"
        })
      event_store.publish_event(dummy_event, stream_name: 'dummy')
      expected_event =
        {
          event_type: "DummyEvent",
          event_id: dummy_event.event_id,
          data: dummy_event.data,
          metadata: {
            timestamp: dummy_event.metadata[:timestamp].as_json
          }
        }

      get '/res/streams/all'
      expect(response.body).to be_collection([expected_event])

      get '/res/streams/dummy'
      expect(response.body).to be_collection([expected_event])
    end

    def all_stream
      { name: "all" }
    end

    def dummy_stream
      { name: "dummy" }
    end

    def event_store
      Rails.configuration.event_store
    end

    RSpec::Matchers.define :be_collection do |structure|
      match do |response_body|
        json_body = JSON.parse(response_body)
        @matcher = RSpec::Matchers::BuiltIn::Match.new(structure)
        @matcher.matches?(json_body.map { |s| s.deep_symbolize_keys })
      end

      failure_message do
        @matcher.failure_message
      end
    end
  end
end