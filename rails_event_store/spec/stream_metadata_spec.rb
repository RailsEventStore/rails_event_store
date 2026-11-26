# frozen_string_literal: true

require "spec_helper"
require "action_controller/railtie"

module RailsEventStore
  ::RSpec.describe Client do
    specify "published metadata events carry request metadata" do
      client =
        Client.new(
          repository:
            RubyEventStore::StreamMetadataAwareRepository.new(
              RubyEventStore::InMemoryRepository.new,
              publish_metadata_events: true,
            ),
        )
      handled = []
      client.subscribe(to: [RubyEventStore::StreamMetadataEvents::StreamTombstoned]) { |event| handled << event }

      client.with_request_metadata(
        "action_dispatch.request_id" => "dummy_id",
        "action_dispatch.remote_ip" => "dummy_ip",
      ) { client.tombstone_stream("some") }

      expect(handled.first.metadata.to_h).to include(
        remote_ip: "dummy_ip",
        request_id: "dummy_id",
        correlation_id: String,
        timestamp: Time,
      )
    end
  end
end
