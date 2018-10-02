require 'ruby_event_store/rom/event_repository'
require 'ruby_event_store/spec/event_repository_lint'

module RubyEventStore::ROM
  RSpec.shared_examples :rom_event_repository do |repository_class|
    subject(:repository) { repository_class.new(rom: env) }

    let(:env) { rom_helper.env }
    let(:container) { env.container }
    let(:rom_db) { container.gateways[:default] }

    around(:each) do |example|
      rom_helper.run_lifecycle { example.run }
    end

    let(:test_race_conditions_auto)  { rom_helper.has_connection_pooling? }
    let(:test_race_conditions_any)   { rom_helper.has_connection_pooling? }
    let(:test_expected_version_auto) { true }
    let(:test_link_events_to_stream) { true }
    let(:test_read_by_event_ids)     { true }
    let(:test_binary) { false }
    let(:test_change) { false }

    let(:default_stream) { RubyEventStore::Stream.new('stream') }
    let(:global_stream) { RubyEventStore::Stream.new('all') }
    let(:mapper) { RubyEventStore::Mappers::NullMapper.new }

    let(:reader) { RubyEventStore::SpecificationReader.new(repository, mapper) }
    let(:specification) { RubyEventStore::Specification.new(reader) }

    it_behaves_like :event_repository, repository_class

    specify "#initialize requires ROM::Env" do
      expect{repository_class.new(rom: nil)}.to raise_error do |err|
        expect(err).to be_a(ArgumentError)
        expect(err.message).to eq("Must specify rom")
      end
    end

    specify "#initialize uses ROM.env by default" do
      expect{repository_class.new}.to raise_error(ArgumentError)
      RubyEventStore::ROM.env = env
      expect{repository_class.new}.not_to raise_error
      RubyEventStore::ROM.env = nil
    end

    specify "#has_event? to raise exception for bad ID" do
      expect(repository.has_event?('0')).to eq(false)
    end

    specify "all considered internal detail" do
      repository.append_to_stream(
        [RubyEventStore::SRecord.new],
        RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
        RubyEventStore::ExpectedVersion.any
      )
      reserved_stream = RubyEventStore::Stream.new("all")

      expect{ repository.read(specification.stream("all").result) }.to raise_error(RubyEventStore::ReservedInternalName)
      expect{ repository.read(specification.stream("all").backward.result) }.to raise_error(RubyEventStore::ReservedInternalName)
      expect{ repository.read(specification.stream("all").from(:head).limit(5).result) }.to raise_error(RubyEventStore::ReservedInternalName)
      expect{ repository.read(specification.stream("all").from(:head).limit(5).backward.result) }.to raise_error(RubyEventStore::ReservedInternalName)
    end

    specify "explicit sorting by position rather than accidental" do
      events = [
        RubyEventStore::SRecord.new(
          event_id: u1 = SecureRandom.uuid,
          data: YAML.dump({}),
          metadata: YAML.dump({}),
          event_type: "TestDomainEvent"
        ),
        RubyEventStore::SRecord.new(
          event_id: u2 = SecureRandom.uuid,
          data: YAML.dump({}),
          metadata: YAML.dump({}),
          event_type: "TestDomainEvent"
        ),
        RubyEventStore::SRecord.new(
          event_id: u3 = SecureRandom.uuid,
          data: YAML.dump({}),
          metadata: YAML.dump({}),
          event_type: "TestDomainEvent"
        )
      ]

      repo = Repositories::Events.new(container)
      repo.create_changeset(events).commit

      expect(repo.events.to_a.size).to eq(3)

      repo.stream_entries.changeset(Repositories::StreamEntries::Create, [
        {stream: default_stream.name, event_id: events[1].event_id, position: 1},
        {stream: default_stream.name, event_id: events[0].event_id, position: 0},
        {stream: default_stream.name, event_id: events[2].event_id, position: 2}
      ]).commit

      expect(repo.stream_entries.to_a.size).to eq(3)

      # ActiveRecord::Schema.define do
      #   self.verbose = false
      #   remove_index :event_store_events_in_streams, [:stream, :position]
      # end

      expect(repository.read(specification.stream("stream").from(:head).limit(3).result).map(&:event_id)).to eq([u1,u2,u3])
      expect(repository.read(specification.stream("stream").result).map(&:event_id)).to eq([u1,u2,u3])

      expect(repository.read(specification.stream("stream").backward.from(:head).limit(3).result).map(&:event_id)).to eq([u3,u2,u1])
      expect(repository.read(specification.stream("stream").backward.result).map(&:event_id)).to eq([u3,u2,u1])
    end

    specify "explicit sorting by id rather than accidental for all events" do
      events = [
        RubyEventStore::SRecord.new(
          event_id: u1 = SecureRandom.uuid,
          data: YAML.dump({}),
          metadata: YAML.dump({}),
          event_type: "TestDomainEvent"
        ),
        RubyEventStore::SRecord.new(
          event_id: u2 = SecureRandom.uuid,
          data: YAML.dump({}),
          metadata: YAML.dump({}),
          event_type: "TestDomainEvent"
        ),
        RubyEventStore::SRecord.new(
          event_id: u3 = SecureRandom.uuid,
          data: YAML.dump({}),
          metadata: YAML.dump({}),
          event_type: "TestDomainEvent"
        )
      ]

      repo = Repositories::Events.new(container)
      repo.create_changeset(events).commit

      expect(repo.events.to_a.size).to eq(3)

      repo.stream_entries.changeset(Repositories::StreamEntries::Create, [
        {stream: global_stream.name, event_id: events[0].event_id, position: 1},
        {stream: global_stream.name, event_id: events[1].event_id, position: 0},
        {stream: global_stream.name, event_id: events[2].event_id, position: 2}
      ]).commit

      expect(repo.stream_entries.to_a.size).to eq(3)

      expect(repository.read(specification.from(:head).limit(3).result).map(&:event_id)).to eq([u1,u2,u3])
      expect(repository.read(specification.from(:head).limit(3).backward.result).map(&:event_id)).to eq([u3,u2,u1])
    end

    specify "nested transaction - events still not persisted if append failed" do
      repository.append_to_stream([
        event = RubyEventStore::SRecord.new(event_id: SecureRandom.uuid),
      ], default_stream, RubyEventStore::ExpectedVersion.none)

      env.unit_of_work do
        expect do
          repository.append_to_stream([
            RubyEventStore::SRecord.new(
              event_id: '9bedf448-e4d0-41a3-a8cd-f94aec7aa763'
            ),
          ], default_stream, RubyEventStore::ExpectedVersion.none)
        end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
        expect(repository.has_event?('9bedf448-e4d0-41a3-a8cd-f94aec7aa763')).to be_falsey
        expect(repository.read(specification.from(:head).limit(2).result).to_a).to eq([event])
      end
      expect(repository.has_event?('9bedf448-e4d0-41a3-a8cd-f94aec7aa763')).to be_falsey
      expect(repository.read(specification.from(:head).limit(2).result).to_a).to eq([event])
    end

    def cleanup_concurrency_test
      rom_helper.close_pool_connection
    end

    def verify_conncurency_assumptions
      expect(rom_helper.connection_pool_size).to eq(5)
    end

    # TODO: Port from AR to ROM
    def additional_limited_concurrency_for_auto_check
      positions = container.relations[:stream_entries].
        ordered(:forward, default_stream).
        map { |entity| entity[:position] }
      expect(positions).to eq((0..positions.size-1).to_a)
    end

    private

    # TODO: Port from AR to ROM
    def count_queries(&block)
      count = 0
      counter_f = ->(_name, _started, _finished, _unique_id, payload) {
        unless %w[ CACHE SCHEMA ].include?(payload[:name])
          count += 1
        end
      }
      # ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)
      count
    end

    # TODO: Port from AR to ROM
    def expect_query(match, &block)
      count = 0
      counter_f = ->(_name, _started, _finished, _unique_id, payload) {
        count += 1 if match === payload[:sql]
      }
      # ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)
      expect(count).to eq(1)
    end
  end
end
