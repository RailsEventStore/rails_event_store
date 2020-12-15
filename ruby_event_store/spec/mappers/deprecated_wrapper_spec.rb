require 'spec_helper'
require 'ruby_event_store/spec/mapper_lint'

module RubyEventStore
  module Mappers
    RSpec.describe DeprecatedWrapper do
      it_behaves_like :mapper, DeprecatedWrapper.new(Default.new), TimeEnrichment.with(TestEvent.new)

      let(:event) { OrderCreated.new }
      let(:record) {
        Record.new(
          event_type: event.event_type,
          event_id:   event.event_id,
          timestamp:  Time.at(0),
          valid_at:   Time.at(0),
          data:       '',
          metadata:   '',
        )
      }

      specify "with deprecated mapper" do
        mapper  = Object.new
        $event  = event
        $record = record
        def mapper.serialized_record_to_event(*); $event;  end
        def mapper.event_to_serialized_record(*); $record; end

        expect(mapper).to receive(:event_to_serialized_record).with(event).and_call_original
        expect(mapper).to receive(:serialized_record_to_event).with(record).and_call_original

        client =
          Client.new(mapper: mapper, repository: InMemoryRepository.new)
        expect {
          client.append(event)
        }.to output(<<~EOW).to_stderr
          Deprecation: Please rename Object#event_to_serialized_record to Object#event_to_record.
        EOW

        expect {
          client.read.last
        }.to output(<<~EOW).to_stderr
          Deprecation: Please rename Object#serialized_record_to_event to Object#record_to_event.
        EOW
      end

      specify "with broken mapper" do
        $event  = event
        $record = record
        broken_mapper  = Object.new
        def broken_mapper.record_to_event(*); raise NoMethodError.new("on record to event"); end
        def broken_mapper.event_to_record(*); raise NoMethodError.new("on event to record"); end

        expect(broken_mapper).to receive(:event_to_record).with(event).and_call_original
        expect(broken_mapper).to receive(:record_to_event).with(record).and_call_original

        repository = InMemoryRepository.new
        client =
          Client.new(mapper: broken_mapper, repository: repository)
        expect {
          client.append(event)
        }.to raise_error(NoMethodError, /on event to record/)

        mapper  = Object.new
        def mapper.record_to_event(*); $event;  end
        def mapper.event_to_record(*); $record; end
        Client.new(mapper: mapper, repository: repository).append(event)
        expect {
          client.read.last
        }.to raise_error(NoMethodError, /on record to event/)
      end
    end
  end
end
