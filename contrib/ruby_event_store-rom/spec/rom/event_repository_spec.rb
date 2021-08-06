require 'spec_helper'
require 'ruby_event_store/spec/event_repository_lint'

module RubyEventStore
  module ROM
    RSpec.describe EventRepository do
      include_examples :event_repository

      let(:rom_helper)     { SpecHelper.new }
      let(:rom_container)  { rom_helper.rom_container }
      let(:repository)     { EventRepository.new(rom: rom_container, serializer: serializer) }
      let(:specification)  { Specification.new(SpecificationReader.new(repository, ::RubyEventStore::Mappers::NullMapper.new)) }
      let(:serializer) {
        case ENV['DATA_TYPE']
        when /json/
          JSON
        else
          YAML
        end
      }

      let(:helper) { rom_helper }

      around(:each) do |example|
        rom_helper.run_lifecycle { example.run }
      end

      specify 'explicit sorting by id rather than accidental for all events' do
        events = [
          SRecord.new(event_id: u1 = SecureRandom.uuid),
          SRecord.new(event_id: u2 = SecureRandom.uuid),
          SRecord.new(event_id: u3 = SecureRandom.uuid)
        ].map{|r| r.serialize(serializer) }

        repo = Repositories::Events.new(rom_container)
        repo.create_changeset(events).commit

        expect(repo.events.to_a.size).to eq(3)

        repo.stream_entries.changeset(Changesets::CreateStreamEntries, [
          { stream: 'all', event_id: events[0].event_id, position: 1 },
          { stream: 'all', event_id: events[1].event_id, position: 0 },
          { stream: 'all', event_id: events[2].event_id, position: 2 }
        ]).commit

        expect(repo.stream_entries.to_a.size).to eq(3)

        expect(repository.read(specification.limit(3).result).map(&:event_id)).to eq([u1, u2, u3])
        expect(repository.read(specification.limit(3).backward.result).map(&:event_id)).to eq([u3, u2, u1])
      end

      specify "does not confuse all with GLOBAL_STREAM" do
        repository.append_to_stream(
          [RubyEventStore::SRecord.new(event_id: "fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a")],
          RubyEventStore::Stream.new('all'),
          RubyEventStore::ExpectedVersion.none
        )

        repository.append_to_stream(
          [RubyEventStore::SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef")],
          RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
          RubyEventStore::ExpectedVersion.any
        )
        expect(repository.read(specification.result))
          .to(contains_ids(%w[fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a a1b49edb-7636-416f-874a-88f94b859bef]))

        expect(repository.read(specification.stream('all').result))
          .to(contains_ids(%w[fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a]))
      end

      specify 'nested transaction - events still not persisted if append failed' do
        repository.append_to_stream([
          event = SRecord.new(event_id: SecureRandom.uuid)
        ], Stream.new('stream'), ExpectedVersion.none)

        UnitOfWork.new(rom_helper.gateway) do
          expect do
            repository.append_to_stream([
              SRecord.new(event_id: '9bedf448-e4d0-41a3-a8cd-f94aec7aa763')
            ], Stream.new('stream'), ExpectedVersion.none)
          end.to raise_error(WrongExpectedEventVersion)
          expect(repository.has_event?('9bedf448-e4d0-41a3-a8cd-f94aec7aa763')).to be_falsey
          expect(repository.read(specification.limit(2).result).to_a).to eq([event])
        end
        expect(repository.has_event?('9bedf448-e4d0-41a3-a8cd-f94aec7aa763')).to be_falsey
        expect(repository.read(specification.limit(2).result).to_a).to eq([event])
      end
    end

    def additional_limited_concurrency_for_auto_check
      positions =
        rom_container
          .relations[:stream_entries]
          .ordered(:forward, RubyEventStore::Stream.new('stream'))
          .map { |entity| entity[:position] }
      expect(positions).to eq((0..positions.size - 1).to_a)
    end
  end
end
