require 'spec_helper'
require 'ruby_event_store/spec/event_repository_lint'
require 'active_support/core_ext/object/try'
require 'active_support/notifications'

module RubyEventStore
  RSpec.describe InstrumentedRepository do
    describe "#append_to_stream" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)
        event1 = Object.new

        instrumented_repository.append_to_stream([event1], "SomeStream", "c456845d-2b86-49c1-bdef-89e57b5d86b1")

        expect(some_repository).to have_received(:append_to_stream).with([event1], "SomeStream", "c456845d-2b86-49c1-bdef-89e57b5d86b1")
      end

      specify "instruments" do
        instrumented_repository = InstrumentedRepository.new(spy, ActiveSupport::Notifications)
        subscribe_to("append_to_stream.repository.rails_event_store") do |notification_calls|
          event1 = Object.new

          instrumented_repository.append_to_stream([event1], "SomeStream", "c456845d-2b86-49c1-bdef-89e57b5d86b1")

          expect(notification_calls).to eq([
            { events: [event1], stream: "SomeStream" }
          ])
        end
      end
    end

    describe "#link_to_stream" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)

        instrumented_repository.link_to_stream([42], "SomeStream", "c456845d-2b86-49c1-bdef-89e57b5d86b1")

        expect(some_repository).to have_received(:link_to_stream).with([42], "SomeStream", "c456845d-2b86-49c1-bdef-89e57b5d86b1")
      end

      specify "instruments" do
        instrumented_repository = InstrumentedRepository.new(spy, ActiveSupport::Notifications)
        subscribe_to("link_to_stream.repository.rails_event_store") do |notification_calls|

          instrumented_repository.link_to_stream([42], "SomeStream", "c456845d-2b86-49c1-bdef-89e57b5d86b1")

          expect(notification_calls).to eq([
            { event_ids: [42], stream: "SomeStream" }
          ])
        end
      end
    end

    describe "#delete_stream" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)

        instrumented_repository.delete_stream("SomeStream")

        expect(some_repository).to have_received(:delete_stream).with("SomeStream")
      end

      specify "instruments" do
        instrumented_repository = InstrumentedRepository.new(spy, ActiveSupport::Notifications)
        subscribe_to("delete_stream.repository.rails_event_store") do |notification_calls|

          instrumented_repository.delete_stream("SomeStream")

          expect(notification_calls).to eq([
            { stream: "SomeStream" }
          ])
        end
      end
    end

    describe "#has_event?" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)

        instrumented_repository.has_event?(42)

        expect(some_repository).to have_received(:has_event?).with(42)
      end
    end

    describe "#last_stream_event" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)

        instrumented_repository.last_stream_event("SomeStream")

        expect(some_repository).to have_received(:last_stream_event).with("SomeStream")
      end
    end

    describe "#read" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)
        specification = double

        instrumented_repository.read(specification)

        expect(some_repository).to have_received(:read).with(specification)
      end

      specify "instruments" do
        instrumented_repository = InstrumentedRepository.new(spy, ActiveSupport::Notifications)
        subscribe_to("read.repository.rails_event_store") do |notification_calls|
          specification = double

          instrumented_repository.read(specification)

          expect(notification_calls).to eq([
            { specification: specification }
          ])
        end
      end
    end

    describe "#count" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)
        specification = double

        instrumented_repository.count(specification)

        expect(some_repository).to have_received(:count).with(specification)
      end

      specify "instruments" do
        instrumented_repository = InstrumentedRepository.new(spy, ActiveSupport::Notifications)
        subscribe_to("count.repository.rails_event_store") do |notification_calls|
          specification = double

          instrumented_repository.count(specification)

          expect(notification_calls).to eq([
            { specification: specification }
          ])
        end
      end
    end

    describe "#update_messages" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)
        messages = double

        instrumented_repository.update_messages(messages)

        expect(some_repository).to have_received(:update_messages).with(messages)
      end

      specify "instruments" do
        instrumented_repository = InstrumentedRepository.new(spy, ActiveSupport::Notifications)
        subscribe_to("update_messages.repository.rails_event_store") do |notification_calls|
          messages = double

          instrumented_repository.update_messages(messages)

          expect(notification_calls).to eq([
            { messages: messages }
          ])
        end
      end
    end

    describe "#streams_of" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)

        uuid = SecureRandom.uuid
        instrumented_repository.streams_of(uuid)

        expect(some_repository).to have_received(:streams_of).with(uuid)
      end

      specify "instruments" do
        instrumented_repository = InstrumentedRepository.new(spy, ActiveSupport::Notifications)
        subscribe_to("streams_of.repository.rails_event_store") do |notification_calls|

          uuid = SecureRandom.uuid
          instrumented_repository.streams_of(uuid)

          expect(notification_calls).to eq([
            { event_id: uuid }
          ])
        end
      end
    end

    def subscribe_to(name)
      received_payloads = []
      callback = ->(_name, _start, _finish, _id, payload) { received_payloads << payload }
      ActiveSupport::Notifications.subscribed(callback, name) do
        yield received_payloads
      end
    end
  end
end

module RubyEventStore
  class InstrumentedRepository
    class SpecHelper < EventRepositoryHelper
      def supports_concurrent_auto?
        false
      end

      def supports_concurrent_any?
        false
      end

      def supports_binary?
        false
      end

      def supports_upsert?
        false
      end
    end
  end
  RSpec.describe InstrumentedRepository do
    include_examples :event_repository
    let(:repository) { InstrumentedRepository.new(InMemoryRepository.new, ActiveSupport::Notifications) }
    let(:helper) { InstrumentedRepository::SpecHelper.new }
  end
end
