# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/event_repository_lint"
require "active_support/core_ext/object/try"
require "active_support/notifications"

module RubyEventStore
  ::RSpec.describe InstrumentedRepository do
    let(:record) { SRecord.new }
    let(:stream) { Stream.new("SomeStream") }
    let(:expected_version) { ExpectedVersion.any }
    let(:event_id) { SecureRandom.uuid }

    describe "#append_to_stream" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)
        instrumented_repository.append_to_stream([record], stream, expected_version)

        expect(some_repository).to have_received(:append_to_stream).with([record], stream, expected_version)
      end

      specify "instruments" do
        instrumented_repository = InstrumentedRepository.new(spy, ActiveSupport::Notifications)
        subscribe_to("append_to_stream.repository.rails_event_store") do |notification_calls|
          instrumented_repository.append_to_stream([record], stream, expected_version)

          expect(notification_calls).to eq([{ events: [record], stream: stream }])
        end
      end
    end

    describe "#link_to_stream" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)
        instrumented_repository.link_to_stream([event_id], stream, expected_version)

        expect(some_repository).to have_received(:link_to_stream).with([event_id], stream, expected_version)
      end

      specify "instruments" do
        instrumented_repository = InstrumentedRepository.new(spy, ActiveSupport::Notifications)
        subscribe_to("link_to_stream.repository.rails_event_store") do |notification_calls|
          instrumented_repository.link_to_stream([event_id], stream, expected_version)

          expect(notification_calls).to eq([{ event_ids: [event_id], stream: stream }])
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

          expect(notification_calls).to eq([{ stream: "SomeStream" }])
        end
      end
    end

    describe "#has_event?" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)
        instrumented_repository.has_event?(event_id)

        expect(some_repository).to have_received(:has_event?).with(event_id)
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

          expect(notification_calls).to eq([{ specification: specification }])
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

          expect(notification_calls).to eq([{ specification: specification }])
        end
      end
    end

    describe "#update_messages" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)
        instrumented_repository.update_messages([record])

        expect(some_repository).to have_received(:update_messages).with([record])
      end

      specify "instruments" do
        instrumented_repository = InstrumentedRepository.new(spy, ActiveSupport::Notifications)
        subscribe_to("update_messages.repository.rails_event_store") do |notification_calls|
          instrumented_repository.update_messages([record])

          expect(notification_calls).to eq([{ messages: [record] }])
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

          expect(notification_calls).to eq([{ event_id: uuid }])
        end
      end
    end

    specify "method unknown by instrumentation but known by repository" do
      some_repository = double("Some repository", custom_method: 42)
      instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)
      block = -> { "block" }
      instrumented_repository.custom_method("arg", keyword: "keyarg", &block)

      expect(instrumented_repository).to respond_to(:custom_method)
      expect(some_repository).to have_received(:custom_method).with("arg", keyword: "keyarg") do |&received_block|
        expect(received_block).to be(block)
      end
    end

    specify "method unknown by instrumentation and unknown by repository" do
      some_repository = InMemoryRepository.new
      instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)

      expect(instrumented_repository).not_to respond_to(:arbitrary_method_name)
      expect { instrumented_repository.arbitrary_method_name }.to raise_error(
        NoMethodError,
        /undefined method.+arbitrary_method_name.+RubyEventStore::InstrumentedRepository/,
      )
    end

    def subscribe_to(name)
      received_payloads = []
      callback = ->(_name, _start, _finish, _id, payload) { received_payloads << payload }
      ActiveSupport::Notifications.subscribed(callback, name) { yield received_payloads }
    end
  end
end

module RubyEventStore
  ::RSpec.describe InstrumentedRepository do
    it_behaves_like "event repository",
                    -> { InstrumentedRepository.new(InMemoryRepository.new, ActiveSupport::Notifications) },
                    SpecHelper.new
  end
end
