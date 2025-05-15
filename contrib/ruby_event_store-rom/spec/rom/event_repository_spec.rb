# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  module ROM
    ::RSpec.describe EventRepository do
      helper = SpecHelper.new
      mk_repository = ->{ EventRepository.new(rom: helper.rom_container, serializer: helper.serializer) }

      it_behaves_like 'event repository', mk_repository, helper

      let(:rom_container) { helper.rom_container }
      let(:repository) { mk_repository.call }
      let(:specification) do
        Specification.new(SpecificationReader.new(repository, ::RubyEventStore::Mappers::Default.new))
      end

      around { |example| helper.run_lifecycle { example.run } }

      specify "nested transaction - events still not persisted if append failed" do
        repository.append_to_stream(
          [event = SRecord.new(event_id: SecureRandom.uuid)],
          Stream.new("stream"),
          ExpectedVersion.none
        )

        helper.with_transaction do
          expect do
            repository.append_to_stream(
              [SRecord.new(event_id: "9bedf448-e4d0-41a3-a8cd-f94aec7aa763")],
              Stream.new("stream"),
              ExpectedVersion.none
            )
          end.to raise_error(WrongExpectedEventVersion)
          expect(repository.has_event?("9bedf448-e4d0-41a3-a8cd-f94aec7aa763")).to be false
          expect(repository.read(specification.limit(2).result).to_a).to eq([event])
        end
        expect(repository.has_event?("9bedf448-e4d0-41a3-a8cd-f94aec7aa763")).to be false
        expect(repository.read(specification.limit(2).result).to_a).to eq([event])
      end

      specify "avoid N+1" do
        repository.append_to_stream(
          [RubyEventStore::SRecord.new, RubyEventStore::SRecord.new],
          RubyEventStore::Stream.new("stream"),
          RubyEventStore::ExpectedVersion.auto
        )

        expect { repository.read(specification.limit(2).result) }.to match_query_count(1)
        expect { repository.read(specification.limit(2).backward.result) }.to match_query_count(1)
        expect { repository.read(specification.stream("stream").result) }.to match_query_count(2)
        expect { repository.read(specification.stream("stream").backward.result) }.to match_query_count(2)
        expect { repository.read(specification.stream("stream").limit(2).result) }.to match_query_count(2)
        expect { repository.read(specification.stream("stream").limit(2).backward.result) }.to match_query_count(2)
      end
    end
  end
end
