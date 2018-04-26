# require 'spec_helper'
# require 'ruby_event_store'
# require 'ruby_event_store/spec/rom/relations/events_lint'

# module RubyEventStore::ROM::Memory::Relations
#   RSpec.describe Events do
#     include SchemaHelper

#     around(:each) do |example|
#       begin
#         establish_database_connection
#         load_database_schema
#         example.run
#       ensure
#         drop_database
#       end
#     end

#     let(:test_race_conditions_auto)  { !(ENV['DATABASE_URL'] =~ /sqlite|memory/) }
#     let(:test_race_conditions_any)   { !(ENV['DATABASE_URL'] =~ /sqlite|memory/) }
#     let(:test_expected_version_auto) { true }
#     let(:test_link_events_to_stream) { true }
#     let(:test_binary) { false }

#     let(:default_stream) { RubyEventStore::Stream.new('stream') }
#     let(:global_stream) { RubyEventStore::Stream.new('all') }
    
#     it_behaves_like :events_relation, Events

#     # specify "#initialize requires ROM::Container" do
#     #   expect{EventRepository.new(rom: nil).append_to_stream([], 'stream', :none)}.to raise_error(NoMethodError)
#     # end

#     # specify "#has_event? to raise exception for bad ID" do
#     #   expect(EventRepository.new.has_event?('0')).to eq(false)
#     # end

#     # specify "all considered internal detail" do
#     #   repository = EventRepository.new
#     #   repository.append_to_stream(
#     #     [event = SRecord.new],
#     #     RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
#     #     RubyEventStore::ExpectedVersion.any
#     #   )
#     #   reserved_stream = RubyEventStore::Stream.new("all")

#     #   expect{ repository.read(RubyEventStore::Specification.new(repository).stream("all").result) }.to raise_error(RubyEventStore::ReservedInternalName)
#     #   expect{ repository.read(RubyEventStore::Specification.new(repository).stream("all").backward.result) }.to raise_error(RubyEventStore::ReservedInternalName)
#     #   expect{ repository.read(RubyEventStore::Specification.new(repository).stream("all").from(:head).limit(5).result) }.to raise_error(RubyEventStore::ReservedInternalName)
#     #   expect{ repository.read(RubyEventStore::Specification.new(repository).stream("all").from(:head).limit(5).backward.result) }.to raise_error(RubyEventStore::ReservedInternalName)
#     # end

#     # # TODO: Port from AR to ROM
#     # xspecify "using preload()" do
#     #   repository = EventRepository.new
#     #   repository.append_to_stream([
#     #     SRecord.new,
#     #     SRecord.new,
#     #   ], default_stream, RubyEventStore::ExpectedVersion.auto)
#     #   c1 = count_queries{ repository.read(RubyEventStore::Specification.new(repository).from(:head).limit(2).result) }
#     #   expect(c1).to eq(2)

#     #   c2 = count_queries{ repository.read(RubyEventStore::Specification.new(repository).from(:head).limit(2).backward.result) }
#     #   expect(c2).to eq(2)

#     #   c3 = count_queries{ repository.read(RubyEventStore::Specification.new(repository).stream("stream").result) }
#     #   expect(c3).to eq(2)

#     #   c4 = count_queries{ repository.read(RubyEventStore::Specification.new(repository).stream("stream").backward.result) }
#     #   expect(c4).to eq(2)

#     #   c5 = count_queries{ repository.read(RubyEventStore::Specification.new(repository).stream("stream").from(:head).limit(2).result) }
#     #   expect(c5).to eq(2)

#     #   c6 = count_queries{ repository.read(RubyEventStore::Specification.new(repository).stream("stream").from(:head).limit(2).backward.result) }
#     #   expect(c6).to eq(2)
#     # end

#     # specify "explicit sorting by position rather than accidental" do
#     #   events = [
#     #     SRecord.new(
#     #       event_id: u1 = SecureRandom.uuid,
#     #       data: YAML.dump({}),
#     #       metadata: YAML.dump({}),
#     #       event_type: "TestDomainEvent"
#     #     ),
#     #     SRecord.new(
#     #       event_id: u2 = SecureRandom.uuid,
#     #       data: YAML.dump({}),
#     #       metadata: YAML.dump({}),
#     #       event_type: "TestDomainEvent"
#     #     ),
#     #     SRecord.new(
#     #       event_id: u3 = SecureRandom.uuid,
#     #       data: YAML.dump({}),
#     #       metadata: YAML.dump({}),
#     #       event_type: "TestDomainEvent"
#     #     )
#     #   ]
      
#     #   repo = Repositories::Events.new(container)
#     #   repo.create_changeset(events).commit

#     #   expect(repo.events.to_a.size).to eq(3)
      
#     #   repo.stream_entries.changeset(Repositories::StreamEntries::Create, [
#     #     {stream: default_stream.name, event_id: events[1].event_id, position: 1},
#     #     {stream: default_stream.name, event_id: events[0].event_id, position: 0},
#     #     {stream: default_stream.name, event_id: events[2].event_id, position: 2}
#     #   ]).commit
      
#     #   expect(repo.stream_entries.to_a.size).to eq(3)
      
#     #   # ActiveRecord::Schema.define do
#     #   #   self.verbose = false
#     #   #   remove_index :event_store_events_in_streams, [:stream, :position]
#     #   # end
#     #   repository = EventRepository.new(rom: env)

#     #   expect(repository.read(RubyEventStore::Specification.new(repository).stream("stream").from(:head).limit(3).result).map(&:event_id)).to eq([u1,u2,u3])
#     #   expect(repository.read(RubyEventStore::Specification.new(repository).stream("stream").result).map(&:event_id)).to eq([u1,u2,u3])

#     #   expect(repository.read(RubyEventStore::Specification.new(repository).stream("stream").backward.from(:head).limit(3).result).map(&:event_id)).to eq([u3,u2,u1])
#     #   expect(repository.read(RubyEventStore::Specification.new(repository).stream("stream").backward.result).map(&:event_id)).to eq([u3,u2,u1])
#     # end

#     # specify "explicit sorting by id rather than accidental for all events" do
#     #   events = [
#     #     SRecord.new(
#     #       event_id: u1 = SecureRandom.uuid,
#     #       data: YAML.dump({}),
#     #       metadata: YAML.dump({}),
#     #       event_type: "TestDomainEvent"
#     #     ),
#     #     SRecord.new(
#     #       event_id: u2 = SecureRandom.uuid,
#     #       data: YAML.dump({}),
#     #       metadata: YAML.dump({}),
#     #       event_type: "TestDomainEvent"
#     #     ),
#     #     SRecord.new(
#     #       event_id: u3 = SecureRandom.uuid,
#     #       data: YAML.dump({}),
#     #       metadata: YAML.dump({}),
#     #       event_type: "TestDomainEvent"
#     #     )
#     #   ]

#     #   repo = Repositories::Events.new(container)
#     #   repo.create_changeset(events).commit

#     #   expect(repo.events.to_a.size).to eq(3)
      
#     #   repo.stream_entries.changeset(Repositories::StreamEntries::Create, [
#     #     {stream: global_stream.name, event_id: events[0].event_id, position: 1},
#     #     {stream: global_stream.name, event_id: events[1].event_id, position: 0},
#     #     {stream: global_stream.name, event_id: events[2].event_id, position: 2}
#     #   ]).commit
      
#     #   expect(repo.stream_entries.to_a.size).to eq(3)
      
#     #   repository = EventRepository.new(rom: env)

#     #   expect(repository.read(RubyEventStore::Specification.new(repository).from(:head).limit(3).result).map(&:event_id)).to eq([u1,u2,u3])
#     #   expect(repository.read(RubyEventStore::Specification.new(repository).from(:head).limit(3).backward.result).map(&:event_id)).to eq([u3,u2,u1])
#     # end

#     # # TODO: Port from AR to ROM
#     # xspecify do
#     #   expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY id ASC LIMIT.*/) do
#     #     repository = EventRepository.new
#     #     repository.read(RubyEventStore::Specification.new(repository).from(:head).limit(3).result)
#     #   end
#     # end

#     # # TODO: Port from AR to ROM
#     # xspecify do
#     #   expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY id DESC LIMIT.*/) do
#     #     repository = EventRepository.new
#     #     repository.read(RubyEventStore::Specification.new(repository).from(:head).limit(3).backward.result)
#     #   end
#     # end

#     # # TODO: Port from AR to ROM
#     # xspecify "explicit ORDER BY position" do
#     #   expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY position DESC LIMIT.*/) do
#     #     repository = EventRepository.new
#     #     repository.append_to_stream([
#     #       SRecord.new,
#     #     ], default_stream, RubyEventStore::ExpectedVersion.auto)
#     #   end
#     # end

#     # specify "nested transaction - events still not persisted if append failed" do
#     #   repository = EventRepository.new
#     #   repository.append_to_stream([
#     #     event = SRecord.new(event_id: SecureRandom.uuid),
#     #   ], default_stream, RubyEventStore::ExpectedVersion.none)

#     #   env.unit_of_work do
#     #     expect do
#     #       repository.append_to_stream([
#     #         SRecord.new(
#     #           event_id: '9bedf448-e4d0-41a3-a8cd-f94aec7aa763'
#     #         ),
#     #       ], default_stream, RubyEventStore::ExpectedVersion.none)
#     #     end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
#     #     expect(repository.has_event?('9bedf448-e4d0-41a3-a8cd-f94aec7aa763')).to be_falsey
#     #     expect(repository.read(RubyEventStore::Specification.new(repository).from(:head).limit(2).result).to_a).to eq([event])
#     #   end
#     #   expect(repository.has_event?('9bedf448-e4d0-41a3-a8cd-f94aec7aa763')).to be_falsey
#     #   expect(repository.read(RubyEventStore::Specification.new(repository).from(:head).limit(2).result).to_a).to eq([event])
#     # end

#     # # TODO: Port from AR to ROM
#     # xspecify "limited query when looking for unexisting events during linking" do
#     #   repository = EventRepository.new
#     #   expect_query(/SELECT.*event_store_events.*id.*FROM.*event_store_events.*WHERE.*event_store_events.*id.*=.*/) do
#     #     expect do
#     #       repository.link_to_stream('72922e65-1b32-4e97-8023-03ae81dd3a27', RubyEventStore::Stream.new('flow'), RubyEventStore::ExpectedVersion.none)
#     #     end.to raise_error(RubyEventStore::EventNotFound)
#     #   end
#     # end

#     # def cleanup_concurrency_test
#     #   rom_db.connection.pool.disconnect
#     # end

#     # def verify_conncurency_assumptions
#     #   expect(rom_db.connection.pool.max_size).to eq(5)
#     #   expect(rom_db.connection.pool.size).to eq(5)
#     # end

#     # # TODO: Port from AR to ROM
#     # def additional_limited_concurrency_for_auto_check
#     #   positions = container.relations[:stream_entries].
#     #     ordered(:forward, default_stream).
#     #     map { |entity| entity[:position] }
#     #   expect(positions).to eq((0..positions.size-1).to_a)
#     # end

#     # private

#     # # TODO: Port from AR to ROM
#     # def count_queries(&block)
#     #   count = 0
#     #   counter_f = ->(_name, _started, _finished, _unique_id, payload) {
#     #     unless %w[ CACHE SCHEMA ].include?(payload[:name])
#     #       count += 1
#     #     end
#     #   }
#     #   # ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)
#     #   count
#     # end

#     # # TODO: Port from AR to ROM
#     # def expect_query(match, &block)
#     #   count = 0
#     #   counter_f = ->(_name, _started, _finished, _unique_id, payload) {
#     #     count += 1 if match === payload[:sql]
#     #   }
#     #   # ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)
#     #   expect(count).to eq(1)
#     # end
#   end
# end
