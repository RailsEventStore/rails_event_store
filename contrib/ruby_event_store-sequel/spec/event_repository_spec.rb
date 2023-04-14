require "spec_helper"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  module Sequel
    ::RSpec.describe EventRepository do
      helper = SpecHelper.new
      mk_repository = ->{ EventRepository.new(sequel: helper.sequel, serializer: helper.serializer) }

      it_behaves_like :event_repository, mk_repository, helper

      around(:each) { |example| helper.run_lifecycle { example.run } }

      let(:repository) { mk_repository.call }
      let(:specification) do
        Specification.new(
          SpecificationReader.new(repository, Mappers::Default.new)
        )
      end

      specify "limited query when looking for non-existing events during linking" do
        expect do
          expect do
            repository.link_to_stream(
              %w[
                72922e65-1b32-4e97-8023-03ae81dd3a27
                d9f6d02a-05f0-4c27-86a9-ad7c4ef73042
              ],
              Stream.new("flow"),
              ExpectedVersion.none
            )
          end.to raise_error(EventNotFound)
        end.to match_query /SELECT .*event_store_events.*event_id.* FROM .*event_store_events.* WHERE .*event_store_events.*.event_id.* IN \('72922e65-1b32-4e97-8023-03ae81dd3a27', 'd9f6d02a-05f0-4c27-86a9-ad7c4ef73042'\).*/
      end
    end
  end
end
