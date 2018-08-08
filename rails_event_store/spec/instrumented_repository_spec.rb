require 'spec_helper'

module RailsEventStore
  RSpec.describe InstrumentedRepository do
    describe "#append_to_stream" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository)
        event1 = Object.new

        instrumented_repository.append_to_stream([event1], "SomeStream", "c456845d-2b86-49c1-bdef-89e57b5d86b1")

        expect(some_repository).to have_received(:append_to_stream).with([event1], "SomeStream", "c456845d-2b86-49c1-bdef-89e57b5d86b1")
      end

      specify "instruments" do
        some_repository = double
        allow(some_repository).to receive(:append_to_stream)
        instrumented_repository = InstrumentedRepository.new(some_repository)
        notification_calls = subscribe_to("append_to_stream.repository.rails_event_store")
        event1 = Object.new

        instrumented_repository.append_to_stream([event1], "SomeStream", "c456845d-2b86-49c1-bdef-89e57b5d86b1")

        expect(notification_calls).to eq([
          { events: [event1], stream: "SomeStream" }
        ])
      end
    end

    describe "#link_to_stream" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository)

        instrumented_repository.link_to_stream([42], "SomeStream", "c456845d-2b86-49c1-bdef-89e57b5d86b1")

        expect(some_repository).to have_received(:link_to_stream).with([42], "SomeStream", "c456845d-2b86-49c1-bdef-89e57b5d86b1")
      end

      specify "instruments" do
        some_repository = double
        allow(some_repository).to receive(:link_to_stream)
        instrumented_repository = InstrumentedRepository.new(some_repository)
        notification_calls = subscribe_to("link_to_stream.repository.rails_event_store")

        instrumented_repository.link_to_stream([42], "SomeStream", "c456845d-2b86-49c1-bdef-89e57b5d86b1")

        expect(notification_calls).to eq([
          { event_ids: [42], stream: "SomeStream" }
        ])
      end
    end

    def subscribe_to(name)
      received_payloads = []
      ActiveSupport::Notifications.subscribe(name) do |_name, _start, _finish, _id, payload|
        received_payloads << payload
      end
      received_payloads
    end
  end
end
