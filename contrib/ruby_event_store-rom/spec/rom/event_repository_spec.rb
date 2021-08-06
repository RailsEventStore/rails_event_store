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

      specify "using preload()" do
        repository.append_to_stream([
          event0 = RubyEventStore::SRecord.new,
          event1 = RubyEventStore::SRecord.new,
        ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
        c1 = count_queries{ repository.read(specification.limit(2).result) }
        expect(c1).to eq(1)

        c2 = count_queries{ repository.read(specification.limit(2).backward.result) }
        expect(c2).to eq(1)

        c3 = count_queries{ repository.read(specification.stream("stream").result) }
        expect(c3).to eq(2)

        c4 = count_queries{ repository.read(specification.stream("stream").backward.result) }
        expect(c4).to eq(2)

        c5 = count_queries{ repository.read(specification.stream("stream").limit(2).result) }
        expect(c5).to eq(2)

        c6 = count_queries{ repository.read(specification.stream("stream").limit(2).backward.result) }
        expect(c6).to eq(2)
      end

      private

      def additional_limited_concurrency_for_auto_check
        positions =
          rom_container
            .relations[:stream_entries]
            .ordered(:forward, RubyEventStore::Stream.new('stream'))
            .map { |entity| entity[:position] }
        expect(positions).to eq((0..positions.size - 1).to_a)
      end

      def count_queries(&block)
        count = 0
        counter_f = ->(_name, _started, _finished, _unique_id, payload) {
          unless %w[ CACHE SCHEMA ].include?(payload[:name])
            count += 1
          end
        }
        ActiveSupport::Notifications.subscribed(counter_f, "sql.rom", &block)
        count
      end
    end
  end
end
