require 'spec_helper'
require 'ruby_event_store/spec/mapper_lint'

module RubyEventStore
  module Mappers
    RSpec.describe DeprecatedWrapper do
      it_behaves_like :mapper, DeprecatedWrapper.new(Default.new), TimeEnrichment.with(TestEvent.new)

      specify "with deprecated mapper" do
        mapper = Object.new
        def mapper.serialized_record_to_event(record)
          OrderCreated.new
        end

        def mapper.event_to_serialized_record(event)
          Record.new(
            event_type: event.event_type,
            event_id:   event.event_id,
            timestamp:  Time.at(0),
            valid_at:   Time.at(0),
            data:       '',
            metadata:   '',
          )
        end
        expect(mapper).to receive(:event_to_serialized_record).and_call_original
        expect(mapper).to receive(:serialized_record_to_event).and_call_original

        client =
          Client.new(mapper: mapper, repository: InMemoryRepository.new)
        expect {
          client.append(OrderCreated.new)
        }.to output(<<~EOW).to_stderr
        Deprecation: Please rename Object#event_to_serialized_record to Object#event_to_record.
        EOW

        expect {
          client.read.last
        }.to output(<<~EOW).to_stderr
        Deprecation: Please rename Object#serialized_record_to_event to Object#record_to_event.
        EOW
      end
    end
  end
end
