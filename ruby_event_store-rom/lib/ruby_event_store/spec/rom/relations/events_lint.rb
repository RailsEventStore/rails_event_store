class SRecord
  def self.new(
    event_id:   SecureRandom.uuid,
    data:       SecureRandom.uuid,
    metadata:   SecureRandom.uuid,
    event_type: SecureRandom.uuid
  )
    RubyEventStore::SerializedRecord.new(
      event_id: event_id,
      data: data,
      metadata: metadata,
      event_type: event_type,
    )
  end
end

# module RubyEventStore
#   module ROM
#     module Memory
#       module Relations
#         class Events < ::ROM::Relation[:memory]
#           schema(:events) do
#             attribute :id, ::ROM::Types::String.meta(primary_key: true)
#             attribute :event_type, ::ROM::Types::String
#             attribute :metadata, ::ROM::Types::String.optional
#             attribute :data, ::ROM::Types::String
#           end

#           def for_stream_entries(_assoc, stream_entries)
#             restrict(id: stream_entries.map { |e| e[:event_id] })
#           end
    
#           def by_pk(id)
#             restrict(id: id)
#           end

#           def exist?
#             to_a.one?
#           end

#           def pluck(name)
#             project(name).map { |e| e[name] }
#           end
#         end
#       end
#     end
#   end
# end


RSpec.shared_examples :events_relation do |relation_class|
  subject(:relation) { container.relations[:events] }

  it 'just created is empty' do
    expect(relation.to_a).to be_empty
  end

  # specify 'append_to_stream returns self' do
  #   repository.
  #     append_to_stream(event = SRecord.new, RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none).
  #     append_to_stream(event = SRecord.new, RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.new(0))
  # end

  # specify 'link_to_stream returns self' do
  #   skip unless test_link_events_to_stream
  #   event0 = SRecord.new
  #   event1 = SRecord.new
  #   repository.
  #     append_to_stream([event0, event1], RubyEventStore::Stream.new("stream0"), RubyEventStore::ExpectedVersion.none).
  #     link_to_stream(event0.event_id, RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.none).
  #     link_to_stream(event1.event_id, RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.new(0))
  # end

  # specify 'adds an initial event to a new stream' do
  #   repository.append_to_stream(event = SRecord.new, RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
  #   expect(read_all_streams_forward(repository, :head, 1).first).to eq(event)
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new('stream')).first).to eq(event)
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new("other_stream"))).to be_empty
  # end

  # specify 'links an initial event to a new stream' do
  #   skip unless test_link_events_to_stream
  #   repository.
  #     append_to_stream(event = SRecord.new, RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none).
  #     link_to_stream(event.event_id, RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.none)

  #   expect(read_all_streams_forward(repository, :head, 1).first).to eq(event)
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new('stream')).first).to eq(event)
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new("flow"))).to eq([event])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new("other"))).to be_empty
  # end

  # specify 'adds multiple initial events to a new stream' do
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
  #   expect(read_all_streams_forward(repository, :head, 2)).to eq([event0, event1])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new('stream'))).to eq([event0, event1])
  # end

  # specify 'links multiple initial events to a new stream' do
  #   skip unless test_link_events_to_stream
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none).link_to_stream([
  #     event0.event_id,
  #     event1.event_id,
  #   ], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.none)
  #   expect(read_all_streams_forward(repository, :head, 2)).to eq([event0, event1])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new("flow"))).to eq([event0, event1])
  # end

  # specify 'correct expected version on second write' do
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
  #   repository.append_to_stream([
  #     event2 = SRecord.new(event_id: SecureRandom.uuid),
  #     event3 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.new(1))
  #   expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1, event2, event3])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new('stream'))).to eq([event0, event1, event2, event3])
  # end

  # specify 'correct expected version on second link' do
  #   skip unless test_link_events_to_stream
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none).append_to_stream([
  #     event2 = SRecord.new(event_id: SecureRandom.uuid),
  #     event3 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.none).link_to_stream([
  #     event0.event_id,
  #     event1.event_id,
  #   ], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.new(1))
  #   expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1, event2, event3])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new("flow"))).to eq([event2, event3, event0, event1])
  # end

  # specify 'incorrect expected version on second write' do
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
  #   expect do
  #     repository.append_to_stream([
  #       event2 = SRecord.new(event_id: SecureRandom.uuid),
  #       event3 = SRecord.new(event_id: SecureRandom.uuid),
  #     ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.new(0))
  #   end.to raise_error(RubyEventStore::WrongExpectedEventVersion)

  #   expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new('stream'))).to eq([event0, event1])
  # end

  # specify 'incorrect expected version on second link' do
  #   skip unless test_link_events_to_stream
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
  #   repository.append_to_stream([
  #     event2 = SRecord.new(event_id: SecureRandom.uuid),
  #     event3 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new("other"), RubyEventStore::ExpectedVersion.none)
  #   expect do
  #     repository.link_to_stream([
  #       event2.event_id,
  #       event3.event_id,
  #     ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.new(0))
  #   end.to raise_error(RubyEventStore::WrongExpectedEventVersion)

  #   expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1, event2, event3])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new('stream'))).to eq([event0, event1])
  # end

  # specify ':none on first and subsequent write' do
  #   repository.append_to_stream([
  #     eventA = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
  #   expect do
  #     repository.append_to_stream([
  #       eventB = SRecord.new(event_id: SecureRandom.uuid),
  #     ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
  #   end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
  #   expect(read_all_streams_forward(repository, :head, 1)).to eq([eventA])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new('stream'))).to eq([eventA])
  # end

  # specify ':none on first and subsequent link' do
  #   skip unless test_link_events_to_stream
  #   repository.append_to_stream([
  #     eventA = SRecord.new(event_id: SecureRandom.uuid),
  #     eventB = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)

  #   repository.link_to_stream([eventA.event_id], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.none)
  #   expect do
  #     repository.link_to_stream([eventB.event_id], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.none)
  #   end.to raise_error(RubyEventStore::WrongExpectedEventVersion)

  #   expect(read_all_streams_forward(repository, :head, 1)).to eq([eventA])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new("flow"))).to eq([eventA])
  # end

  # specify ':any allows stream with best-effort order and no guarantee' do
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.any)
  #   repository.append_to_stream([
  #     event2 = SRecord.new(event_id: SecureRandom.uuid),
  #     event3 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.any)
  #   expect(read_all_streams_forward(repository, :head, 4).to_set).to eq(Set.new([event0, event1, event2, event3]))
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new('stream')).to_set).to eq(Set.new([event0, event1, event2, event3]))
  # end

  # specify ':any allows linking in stream with best-effort order and no guarantee' do
  #   skip unless test_link_events_to_stream
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #     event2 = SRecord.new(event_id: SecureRandom.uuid),
  #     event3 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.any)

  #   repository.link_to_stream([
  #     event0.event_id, event1.event_id,
  #   ], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.any)
  #   repository.link_to_stream([
  #     event2.event_id, event3.event_id,
  #   ], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.any)

  #   expect(read_all_streams_forward(repository, :head, 4).to_set).to eq(Set.new([event0, event1, event2, event3]))
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new("flow")).to_set).to eq(Set.new([event0, event1, event2, event3]))
  # end

  # specify ':auto queries for last position in given stream' do
  #   skip unless test_expected_version_auto
  #   repository.append_to_stream([
  #     eventA = SRecord.new(event_id: SecureRandom.uuid),
  #     eventB = SRecord.new(event_id: SecureRandom.uuid),
  #     eventC = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new("another"), RubyEventStore::ExpectedVersion.auto)
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
  #   repository.append_to_stream([
  #     event2 = SRecord.new(event_id: SecureRandom.uuid),
  #     event3 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.new(1))
  # end

  # specify ':auto queries for last position in given stream when linking' do
  #   skip unless test_expected_version_auto
  #   skip unless test_link_events_to_stream
  #   repository.append_to_stream([
  #     eventA = SRecord.new(event_id: SecureRandom.uuid),
  #     eventB = SRecord.new(event_id: SecureRandom.uuid),
  #     eventC = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new("another"), RubyEventStore::ExpectedVersion.auto)
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
  #   repository.link_to_stream([
  #     eventA.event_id,
  #     eventB.event_id,
  #     eventC.event_id,
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.new(1))
  # end

  # specify ':auto starts from 0' do
  #   skip unless test_expected_version_auto
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
  #   expect do
  #     repository.append_to_stream([
  #       event1 = SRecord.new(event_id: SecureRandom.uuid),
  #     ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
  #   end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
  # end

  # specify ':auto linking starts from 0' do
  #   skip unless test_expected_version_auto
  #   skip unless test_link_events_to_stream
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new("whatever"), RubyEventStore::ExpectedVersion.auto)
  #   repository.link_to_stream([
  #     event0.event_id,
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
  #   expect do
  #     repository.append_to_stream([
  #       event1 = SRecord.new(event_id: SecureRandom.uuid),
  #     ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
  #   end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
  # end

  # specify ':auto queries for last position and follows in incremental way' do
  #   skip unless test_expected_version_auto
  #   # It is expected that there is higher level lock
  #   # So this query is safe from race conditions
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
  #   repository.append_to_stream([
  #     event2 = SRecord.new(event_id: SecureRandom.uuid),
  #     event3 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
  #   expect(read_all_streams_forward(repository, :head, 4)).to eq([
  #     event0, event1,
  #     event2, event3
  #   ])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new('stream'))).to eq([event0, event1, event2, event3])
  # end

  # specify ':auto queries for last position and follows in incremental way when linking' do
  #   skip unless test_expected_version_auto
  #   skip unless test_link_events_to_stream
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #     event2 = SRecord.new(event_id: SecureRandom.uuid),
  #     event3 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
  #   repository.link_to_stream([
  #     event0.event_id, event1.event_id,
  #   ], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.auto)
  #   repository.link_to_stream([
  #     event2.event_id, event3.event_id,
  #   ], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.auto)
  #   expect(read_all_streams_forward(repository, :head, 4)).to eq([
  #     event0, event1,
  #     event2, event3
  #   ])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new("flow"))).to eq([event0, event1, event2, event3])
  # end

  # specify ':auto is compatible with manual expectation' do
  #   skip unless test_expected_version_auto
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
  #   repository.append_to_stream([
  #     event2 = SRecord.new(event_id: SecureRandom.uuid),
  #     event3 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.new(1))
  #   expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1, event2, event3])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new('stream'))).to eq([event0, event1, event2, event3])
  # end

  # specify ':auto is compatible with manual expectation when linking' do
  #   skip unless test_expected_version_auto
  #   skip unless test_link_events_to_stream
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
  #   repository.link_to_stream([
  #     event0.event_id,
  #   ], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.auto)
  #   repository.link_to_stream([
  #     event1.event_id,
  #   ], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.new(0))
  #   expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1,])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new("flow"))).to eq([event0, event1,])
  # end

  # specify 'manual is compatible with auto expectation' do
  #   skip unless test_expected_version_auto
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
  #   repository.append_to_stream([
  #     event2 = SRecord.new(event_id: SecureRandom.uuid),
  #     event3 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
  #   expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1, event2, event3])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new('stream'))).to eq([event0, event1, event2, event3])
  # end

  # specify 'manual is compatible with auto expectation when linking' do
  #   skip unless test_expected_version_auto
  #   skip unless test_link_events_to_stream
  #   repository.append_to_stream([
  #     event0 = SRecord.new(event_id: SecureRandom.uuid),
  #     event1 = SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
  #   repository.link_to_stream([
  #     event0.event_id,
  #   ], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.none)
  #   repository.link_to_stream([
  #     event1.event_id,
  #   ], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.auto)
  #   expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1])
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new("flow"))).to eq([event0, event1])
  # end

  # specify 'unlimited concurrency for :any - everything should succeed', timeout: 10, mutant: false do
  #   skip unless test_race_conditions_any
  #   verify_conncurency_assumptions
  #   begin
  #     concurrency_level = 4

  #     fail_occurred = false
  #     wait_for_it  = true

  #     threads = concurrency_level.times.map do |i|
  #       Thread.new do
  #         true while wait_for_it
  #         begin
  #           100.times do |j|
  #             eid = "0000000#{i}-#{sprintf("%04d", j)}-0000-0000-000000000000"
  #             repository.append_to_stream([
  #               SRecord.new(event_id: eid),
  #             ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.any)
  #           end
  #         rescue RubyEventStore::WrongExpectedEventVersion
  #           fail_occurred = true
  #         end
  #       end
  #     end
  #     wait_for_it = false
  #     threads.each(&:join)
  #     expect(fail_occurred).to eq(false)
  #     expect(read_stream_events_forward(repository, RubyEventStore::Stream.new('stream')).size).to eq(400)
  #     events_in_stream = read_stream_events_forward(repository, RubyEventStore::Stream.new('stream'))
  #     expect(events_in_stream.size).to eq(400)
  #     events0 = events_in_stream.select do |ev|
  #       ev.event_id.start_with?("0-")
  #     end
  #     expect(events0).to eq(events0.sort_by{|ev| ev.event_id })
  #   ensure
  #     cleanup_concurrency_test
  #   end
  # end

  # specify 'unlimited concurrency for :any - everything should succeed when linking', timeout: 10, mutant: false do
  #   skip unless test_race_conditions_any
  #   skip unless test_link_events_to_stream
  #   verify_conncurency_assumptions
  #   begin
  #     concurrency_level = 4

  #     fail_occurred = false
  #     wait_for_it  = true

  #     concurrency_level.times.map do |i|
  #       100.times do |j|
  #         eid = "0000000#{i}-#{sprintf("%04d", j)}-0000-0000-000000000000"
  #         repository.append_to_stream([
  #           SRecord.new(event_id: eid),
  #         ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.any)
  #       end
  #     end

  #     threads = concurrency_level.times.map do |i|
  #       Thread.new do
  #         true while wait_for_it
  #         begin
  #           100.times do |j|
  #             eid = "0000000#{i}-#{sprintf("%04d", j)}-0000-0000-000000000000"
  #             repository.link_to_stream(eid, RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.any)
  #           end
  #         rescue RubyEventStore::WrongExpectedEventVersion
  #           fail_occurred = true
  #         end
  #       end
  #     end
  #     wait_for_it = false
  #     threads.each(&:join)
  #     expect(fail_occurred).to eq(false)
  #     expect(read_stream_events_forward(repository, RubyEventStore::Stream.new("flow")).size).to eq(400)
  #     events_in_stream = read_stream_events_forward(repository, RubyEventStore::Stream.new("flow"))
  #     expect(events_in_stream.size).to eq(400)
  #     events0 = events_in_stream.select do |ev|
  #       ev.event_id.start_with?("0-")
  #     end
  #     expect(events0).to eq(events0.sort_by{|ev| ev.event_id })
  #   ensure
  #     cleanup_concurrency_test
  #   end
  # end

  # specify 'limited concurrency for :auto - some operations will fail without outside lock, stream is ordered' do
  #   skip unless test_expected_version_auto
  #   skip unless test_race_conditions_auto
  #   verify_conncurency_assumptions
  #   begin
  #     concurrency_level = 4

  #     fail_occurred = 0
  #     wait_for_it  = true

  #     threads = concurrency_level.times.map do |i|
  #       Thread.new do
  #         true while wait_for_it
  #         100.times do |j|
  #           begin
  #             eid = "0000000#{i}-#{sprintf("%04d", j)}-0000-0000-000000000000"
  #             repository.append_to_stream([
  #               SRecord.new(event_id: eid),
  #             ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
  #             sleep(rand(concurrency_level) / 1000.0)
  #           rescue RubyEventStore::WrongExpectedEventVersion
  #             fail_occurred +=1
  #           end
  #         end
  #       end
  #     end
  #     wait_for_it = false
  #     threads.each(&:join)
  #     expect(fail_occurred).to be > 0
  #     events_in_stream = read_stream_events_forward(repository, RubyEventStore::Stream.new('stream'))
  #     expect(events_in_stream.size).to be < 400
  #     expect(events_in_stream.size).to be >= 100
  #     events0 = events_in_stream.select do |ev|
  #       ev.event_id.start_with?("0-")
  #     end
  #     expect(events0).to eq(events0.sort_by{|ev| ev.event_id })
  #     additional_limited_concurrency_for_auto_check
  #   ensure
  #     cleanup_concurrency_test
  #   end
  # end

  # specify 'limited concurrency for :auto - some operations will fail without outside lock, stream is ordered' do
  #   skip unless test_expected_version_auto
  #   skip unless test_race_conditions_auto
  #   skip unless test_link_events_to_stream

  #   verify_conncurency_assumptions
  #   begin
  #     concurrency_level = 4

  #     concurrency_level.times.map do |i|
  #       100.times do |j|
  #         eid = "0000000#{i}-#{sprintf("%04d", j)}-0000-0000-000000000000"
  #         repository.append_to_stream([
  #           SRecord.new(event_id: eid),
  #         ], RubyEventStore::Stream.new("whatever"), RubyEventStore::ExpectedVersion.any)
  #       end
  #     end

  #     fail_occurred = 0
  #     wait_for_it  = true

  #     threads = concurrency_level.times.map do |i|
  #       Thread.new do
  #         true while wait_for_it
  #         100.times do |j|
  #           begin
  #             eid = "0000000#{i}-#{sprintf("%04d", j)}-0000-0000-000000000000"
  #             repository.link_to_stream(eid, RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
  #             sleep(rand(concurrency_level) / 1000.0)
  #           rescue RubyEventStore::WrongExpectedEventVersion
  #             fail_occurred +=1
  #           end
  #         end
  #       end
  #     end
  #     wait_for_it = false
  #     threads.each(&:join)
  #     expect(fail_occurred).to be > 0
  #     events_in_stream = read_stream_events_forward(repository, RubyEventStore::Stream.new('stream'))
  #     expect(events_in_stream.size).to be < 400
  #     expect(events_in_stream.size).to be >= 100
  #     events0 = events_in_stream.select do |ev|
  #       ev.event_id.start_with?("0-")
  #     end
  #     expect(events0).to eq(events0.sort_by{|ev| ev.event_id })
  #     additional_limited_concurrency_for_auto_check
  #   ensure
  #     cleanup_concurrency_test
  #   end
  # end

  # it 'appended event is stored in given stream' do
  #   expected_event = SRecord.new
  #   repository.append_to_stream(expected_event, RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.any)
  #   expect(read_all_streams_forward(repository, :head, 1).first).to eq(expected_event)
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new('stream')).first).to eq(expected_event)
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new("other_stream"))).to be_empty
  # end

  # it 'data attributes are retrieved' do
  #   event = SRecord.new(data: "{ order_id: 3 }")
  #   repository.append_to_stream(event, RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.any)
  #   retrieved_event = read_all_streams_forward(repository, :head, 1).first
  #   expect(retrieved_event.data).to eq("{ order_id: 3 }")
  # end

  # it 'metadata attributes are retrieved' do
  #   event = SRecord.new(metadata: "{ request_id: 3 }")
  #   repository.append_to_stream(event, RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.any)
  #   retrieved_event = read_all_streams_forward(repository, :head, 1).first
  #   expect(retrieved_event.metadata).to eq("{ request_id: 3 }")
  # end

  # it 'data and metadata attributes are retrieved when linking' do
  #   skip unless test_link_events_to_stream
  #   event = SRecord.new(
  #     data: "{ order_id: 3 }",
  #     metadata: "{ request_id: 4 }",
  #   )
  #   repository.
  #     append_to_stream(event, RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.any).
  #     link_to_stream(event.event_id, RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.any)
  #   retrieved_event = read_stream_events_forward(repository, RubyEventStore::Stream.new("flow")).first
  #   expect(retrieved_event.metadata).to eq("{ request_id: 4 }")
  #   expect(retrieved_event.data).to eq("{ order_id: 3 }")
  #   expect(event).to eq(retrieved_event)
  # end

  # it 'does not have deleted streams' do
  #   repository.append_to_stream(e1 = SRecord.new, RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
  #   repository.append_to_stream(e2 = SRecord.new, RubyEventStore::Stream.new("other_stream"), RubyEventStore::ExpectedVersion.none)

  #   repository.delete_stream(RubyEventStore::Stream.new('stream'))
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new('stream'))).to be_empty
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new("other_stream"))).to eq([e2])
  #   expect(read_all_streams_forward(repository, :head, 10)).to eq([e1,e2])
  # end

  # it 'does not have deleted streams with linked events' do
  #   skip unless test_link_events_to_stream
  #   repository.
  #     append_to_stream(e1 = SRecord.new, RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none).
  #     link_to_stream(e1.event_id, RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.none)

  #   repository.delete_stream(RubyEventStore::Stream.new("flow"))
  #   expect(read_stream_events_forward(repository, RubyEventStore::Stream.new("flow"))).to be_empty
  #   expect(read_all_streams_forward(repository, :head, 10)).to eq([e1])
  # end

  # it 'has or has not domain event' do
  #   just_an_id = 'd5c134c2-db65-4e87-b6ea-d196f8f1a292'
  #   repository.append_to_stream(SRecord.new(event_id: just_an_id), RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)

  #   expect(repository.has_event?(just_an_id)).to be_truthy
  #   expect(repository.has_event?(just_an_id.clone)).to be_truthy
  #   expect(repository.has_event?('any other id')).to be_falsey

  #   repository.delete_stream(RubyEventStore::Stream.new('stream'))
  #   expect(repository.has_event?(just_an_id)).to be_truthy
  #   expect(repository.has_event?(just_an_id.clone)).to be_truthy
  # end

  # it 'knows last event in stream' do
  #   repository.append_to_stream(a =SRecord.new(event_id: '00000000-0000-0000-0000-000000000001'), RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
  #   repository.append_to_stream(b = SRecord.new(event_id: '00000000-0000-0000-0000-000000000002'), RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.new(0))

  #   expect(repository.last_stream_event(RubyEventStore::Stream.new('stream'))).to eq(b)
  #   expect(repository.last_stream_event(RubyEventStore::Stream.new("other_stream"))).to be_nil
  # end

  # it 'knows last event in stream when linked' do
  #   skip unless test_link_events_to_stream
  #   repository.append_to_stream([
  #       e0 = SRecord.new(event_id: '00000000-0000-0000-0000-000000000001'),
  #       e1 = SRecord.new(event_id: '00000000-0000-0000-0000-000000000002'),
  #     ],
  #     RubyEventStore::Stream.new('stream'),
  #     RubyEventStore::ExpectedVersion.none
  #   ).link_to_stream([e1.event_id, e0.event_id], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.none)
  #   expect(repository.last_stream_event(RubyEventStore::Stream.new("flow"))).to eq(e0)
  # end

  # it 'reads batch of events from stream forward & backward' do
  #   events = %w[
  #     96c920b1-cdd0-40f4-907c-861b9fff7d02
  #     56404f79-0ba0-4aa0-8524-dc3436368ca0
  #     6a54dd21-f9d8-4857-a195-f5588d9e406c
  #     0e50a9cd-f981-4e39-93d5-697fc7285b98
  #     d85589bc-b993-41d4-812f-fc631d9185d5
  #     96bdacda-77dd-4d7d-973d-cbdaa5842855
  #     94688199-e6b7-4180-bf8e-825b6808e6cc
  #     68fab040-741e-4bc2-9cca-5b8855b0ca19
  #     ab60114c-011d-4d58-ab31-7ba65d99975e
  #     868cac42-3d19-4b39-84e8-cd32d65c2445
  #   ].map { |id| SRecord.new(event_id: id) }
  #   repository.append_to_stream(SRecord.new, RubyEventStore::Stream.new("other_stream"), RubyEventStore::ExpectedVersion.none)
  #   events.each.with_index do |event, index|
  #     repository.append_to_stream(event, RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.new(index - 1))
  #   end
  #   repository.append_to_stream(SRecord.new, RubyEventStore::Stream.new("other_stream"), RubyEventStore::ExpectedVersion.new(0))

  #   expect(read_events_forward(repository, RubyEventStore::Stream.new('stream'), :head, 3)).to eq(events.first(3))
  #   expect(read_events_forward(repository, RubyEventStore::Stream.new('stream'), :head, 100)).to eq(events)
  #   expect(read_events_forward(repository, RubyEventStore::Stream.new('stream'), events[4].event_id, 4)).to eq(events[5..8])
  #   expect(read_events_forward(repository, RubyEventStore::Stream.new('stream'), events[4].event_id, 100)).to eq(events[5..9])

  #   expect(read_events_backward(repository, RubyEventStore::Stream.new('stream'), :head, 3)).to eq(events.last(3).reverse)
  #   expect(read_events_backward(repository, RubyEventStore::Stream.new('stream'), :head, 100)).to eq(events.reverse)
  #   expect(read_events_backward(repository, RubyEventStore::Stream.new('stream'), events[4].event_id, 4)).to eq(events.first(4).reverse)
  #   expect(read_events_backward(repository, RubyEventStore::Stream.new('stream'), events[4].event_id, 100)).to eq(events.first(4).reverse)
  # end

  # it 'reads batch of linked events from stream forward & backward' do
  #   skip unless test_link_events_to_stream
  #   events = %w[
  #     96c920b1-cdd0-40f4-907c-861b9fff7d02
  #     56404f79-0ba0-4aa0-8524-dc3436368ca0
  #     6a54dd21-f9d8-4857-a195-f5588d9e406c
  #     0e50a9cd-f981-4e39-93d5-697fc7285b98
  #     d85589bc-b993-41d4-812f-fc631d9185d5
  #     96bdacda-77dd-4d7d-973d-cbdaa5842855
  #     94688199-e6b7-4180-bf8e-825b6808e6cc
  #     68fab040-741e-4bc2-9cca-5b8855b0ca19
  #     ab60114c-011d-4d58-ab31-7ba65d99975e
  #     868cac42-3d19-4b39-84e8-cd32d65c2445
  #   ].map { |id| SRecord.new(event_id: id) }
  #   repository.append_to_stream(SRecord.new, RubyEventStore::Stream.new("other_stream"), RubyEventStore::ExpectedVersion.none)
  #   events.each.with_index do |event, index|
  #     repository.
  #       append_to_stream(event, RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.new(index - 1)).
  #       link_to_stream(event.event_id, RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.new(index - 1))
  #   end
  #   repository.append_to_stream(SRecord.new, RubyEventStore::Stream.new("other_stream"), RubyEventStore::ExpectedVersion.new(0))

  #   expect(read_events_forward(repository, RubyEventStore::Stream.new("flow"), :head, 3)).to eq(events.first(3))
  #   expect(read_events_forward(repository, RubyEventStore::Stream.new("flow"), :head, 100)).to eq(events)
  #   expect(read_events_forward(repository, RubyEventStore::Stream.new("flow"), events[4].event_id, 4)).to eq(events[5..8])
  #   expect(read_events_forward(repository, RubyEventStore::Stream.new("flow"), events[4].event_id, 100)).to eq(events[5..9])

  #   expect(read_events_backward(repository, RubyEventStore::Stream.new("flow"), :head, 3)).to eq(events.last(3).reverse)
  #   expect(read_events_backward(repository, RubyEventStore::Stream.new("flow"), :head, 100)).to eq(events.reverse)
  #   expect(read_events_backward(repository, RubyEventStore::Stream.new("flow"), events[4].event_id, 4)).to eq(events.first(4).reverse)
  #   expect(read_events_backward(repository, RubyEventStore::Stream.new("flow"), events[4].event_id, 100)).to eq(events.first(4).reverse)
  # end

  # it 'reads all stream events forward & backward' do
  #   s1 = RubyEventStore::Stream.new('stream')
  #   s2 = RubyEventStore::Stream.new("other_stream")
  #   repository.
  #     append_to_stream(a = SRecord.new(event_id: '7010d298-ab69-4bb1-9251-f3466b5d1282'), s1, RubyEventStore::ExpectedVersion.none).
  #     append_to_stream(b = SRecord.new(event_id: '34f88aca-aaba-4ca0-9256-8017b47528c5'), s2, RubyEventStore::ExpectedVersion.none).
  #     append_to_stream(c = SRecord.new(event_id: '8e61c864-ceae-4684-8726-97c34eb8fc4f'), s1, RubyEventStore::ExpectedVersion.new(0)).
  #     append_to_stream(d = SRecord.new(event_id: '30963ed9-6349-450b-ac9b-8ea50115b3bd'), s2, RubyEventStore::ExpectedVersion.new(0)).
  #     append_to_stream(e = SRecord.new(event_id: '5bdc58b7-e8a7-4621-afd6-ccb828d72457'), s2, RubyEventStore::ExpectedVersion.new(1))

  #   expect(read_stream_events_forward(repository, s1)).to eq [a,c]
  #   expect(read_stream_events_backward(repository, s1)).to eq [c,a]
  # end

  # it 'reads all stream linked events forward & backward' do
  #   skip unless test_link_events_to_stream
  #   s1, fs1, fs2 = RubyEventStore::Stream.new('stream'), RubyEventStore::Stream.new("flow"), RubyEventStore::Stream.new("other_flow")
  #   repository.
  #     append_to_stream(a = SRecord.new(event_id: '7010d298-ab69-4bb1-9251-f3466b5d1282'), s1, RubyEventStore::ExpectedVersion.none).
  #     append_to_stream(b = SRecord.new(event_id: '34f88aca-aaba-4ca0-9256-8017b47528c5'), s1, RubyEventStore::ExpectedVersion.new(0)).
  #     append_to_stream(c = SRecord.new(event_id: '8e61c864-ceae-4684-8726-97c34eb8fc4f'), s1, RubyEventStore::ExpectedVersion.new(1)).
  #     append_to_stream(d = SRecord.new(event_id: '30963ed9-6349-450b-ac9b-8ea50115b3bd'), s1, RubyEventStore::ExpectedVersion.new(2)).
  #     append_to_stream(e = SRecord.new(event_id: '5bdc58b7-e8a7-4621-afd6-ccb828d72457'), s1, RubyEventStore::ExpectedVersion.new(3)).
  #     link_to_stream('7010d298-ab69-4bb1-9251-f3466b5d1282', fs1, RubyEventStore::ExpectedVersion.none).
  #     link_to_stream('34f88aca-aaba-4ca0-9256-8017b47528c5', fs2, RubyEventStore::ExpectedVersion.none).
  #     link_to_stream('8e61c864-ceae-4684-8726-97c34eb8fc4f', fs1, RubyEventStore::ExpectedVersion.new(0)).
  #     link_to_stream('30963ed9-6349-450b-ac9b-8ea50115b3bd', fs2, RubyEventStore::ExpectedVersion.new(0)).
  #     link_to_stream('5bdc58b7-e8a7-4621-afd6-ccb828d72457', fs2, RubyEventStore::ExpectedVersion.new(1))

  #   expect(read_stream_events_forward(repository, fs1)).to eq [a,c]
  #   expect(read_stream_events_backward(repository, fs1)).to eq [c,a]
  # end

  # it 'reads batch of events from all streams forward & backward' do
  #   events = %w[
  #     96c920b1-cdd0-40f4-907c-861b9fff7d02
  #     56404f79-0ba0-4aa0-8524-dc3436368ca0
  #     6a54dd21-f9d8-4857-a195-f5588d9e406c
  #     0e50a9cd-f981-4e39-93d5-697fc7285b98
  #     d85589bc-b993-41d4-812f-fc631d9185d5
  #     96bdacda-77dd-4d7d-973d-cbdaa5842855
  #     94688199-e6b7-4180-bf8e-825b6808e6cc
  #     68fab040-741e-4bc2-9cca-5b8855b0ca19
  #     ab60114c-011d-4d58-ab31-7ba65d99975e
  #     868cac42-3d19-4b39-84e8-cd32d65c2445
  #   ].map { |id| SRecord.new(event_id: id) }
  #   events.each do |ev|
  #     repository.append_to_stream(ev, RubyEventStore::Stream.new(SecureRandom.uuid), RubyEventStore::ExpectedVersion.none)
  #   end

  #   expect(read_all_streams_forward(repository, :head, 3)).to eq(events.first(3))
  #   expect(read_all_streams_forward(repository, :head, 100)).to eq(events)
  #   expect(read_all_streams_forward(repository, events[4].event_id, 4)).to eq(events[5..8])
  #   expect(read_all_streams_forward(repository, events[4].event_id, 100)).to eq(events[5..9])

  #   expect(read_all_streams_backward(repository, :head, 3)).to eq(events.last(3).reverse)
  #   expect(read_all_streams_backward(repository, :head, 100)).to eq(events.reverse)
  #   expect(read_all_streams_backward(repository, events[4].event_id, 4)).to eq(events.first(4).reverse)
  #   expect(read_all_streams_backward(repository, events[4].event_id, 100)).to eq(events.first(4).reverse)
  # end

  # it 'linked events do not affect reading from all streams - no duplicates' do
  #   skip unless test_link_events_to_stream
  #   events = %w[
  #     96c920b1-cdd0-40f4-907c-861b9fff7d02
  #     56404f79-0ba0-4aa0-8524-dc3436368ca0
  #     6a54dd21-f9d8-4857-a195-f5588d9e406c
  #     0e50a9cd-f981-4e39-93d5-697fc7285b98
  #     d85589bc-b993-41d4-812f-fc631d9185d5
  #     96bdacda-77dd-4d7d-973d-cbdaa5842855
  #     94688199-e6b7-4180-bf8e-825b6808e6cc
  #     68fab040-741e-4bc2-9cca-5b8855b0ca19
  #     ab60114c-011d-4d58-ab31-7ba65d99975e
  #     868cac42-3d19-4b39-84e8-cd32d65c2445
  #   ].map { |id| SRecord.new(event_id: id) }
  #   events.each do |ev|
  #     repository.
  #       append_to_stream(ev, RubyEventStore::Stream.new(SecureRandom.uuid), RubyEventStore::ExpectedVersion.none).
  #       link_to_stream(ev.event_id, RubyEventStore::Stream.new(SecureRandom.uuid), RubyEventStore::ExpectedVersion.none)
  #   end

  #   expect(read_all_streams_forward(repository, :head, 3)).to eq(events.first(3))
  #   expect(read_all_streams_forward(repository, :head, 100)).to eq(events)
  #   expect(read_all_streams_forward(repository, events[4].event_id, 4)).to eq(events[5..8])
  #   expect(read_all_streams_forward(repository, events[4].event_id, 100)).to eq(events[5..9])

  #   expect(read_all_streams_backward(repository, :head, 3)).to eq(events.last(3).reverse)
  #   expect(read_all_streams_backward(repository, :head, 100)).to eq(events.reverse)
  #   expect(read_all_streams_backward(repository, events[4].event_id, 4)).to eq(events.first(4).reverse)
  #   expect(read_all_streams_backward(repository, events[4].event_id, 100)).to eq(events.first(4).reverse)
  # end

  # it 'reads events different uuid object but same content' do
  #   events = %w[
  #     96c920b1-cdd0-40f4-907c-861b9fff7d02
  #     56404f79-0ba0-4aa0-8524-dc3436368ca0
  #   ].map{|id| SRecord.new(event_id: id) }
  #   repository.append_to_stream(events.first, RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
  #   repository.append_to_stream(events.last,  RubyEventStore::Stream.new('stream'),  RubyEventStore::ExpectedVersion.new(0))

  #   expect(read_all_streams_forward(repository, "96c920b1-cdd0-40f4-907c-861b9fff7d02", 1)).to eq([events.last])
  #   expect(read_all_streams_backward(repository, "56404f79-0ba0-4aa0-8524-dc3436368ca0", 1)).to eq([events.first])

  #   expect(read_events_forward(repository, RubyEventStore::Stream.new('stream'), "96c920b1-cdd0-40f4-907c-861b9fff7d02", 1)).to eq([events.last])
  #   expect(read_events_backward(repository, RubyEventStore::Stream.new('stream'), "56404f79-0ba0-4aa0-8524-dc3436368ca0", 1)).to eq([events.first])
  # end

  # it 'does not allow same event twice in a stream' do
  #   repository.append_to_stream(
  #     SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
  #     RubyEventStore::Stream.new('stream'),
  #     RubyEventStore::ExpectedVersion.none
  #   )
  #   expect do
  #     repository.append_to_stream(
  #       SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
  #       RubyEventStore::Stream.new('stream'),
  #       RubyEventStore::ExpectedVersion.new(0)
  #     )
  #   end.to raise_error(RubyEventStore::EventDuplicatedInStream)
  # end

  # it 'does not allow same event twice' do
  #   repository.append_to_stream(
  #     SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
  #     RubyEventStore::Stream.new('stream'),
  #     RubyEventStore::ExpectedVersion.none
  #   )
  #   expect do
  #     repository.append_to_stream(
  #       SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
  #       RubyEventStore::Stream.new("another"),
  #       RubyEventStore::ExpectedVersion.none
  #     )
  #   end.to raise_error(RubyEventStore::EventDuplicatedInStream)
  # end

  # it 'does not allow linking same event twice in a stream' do
  #   skip unless test_link_events_to_stream
  #   repository.append_to_stream([
  #       SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
  #     ], RubyEventStore::Stream.new('stream'),
  #     RubyEventStore::ExpectedVersion.none
  #   ).link_to_stream("a1b49edb-7636-416f-874a-88f94b859bef", RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.none)
  #   expect do
  #     repository.link_to_stream("a1b49edb-7636-416f-874a-88f94b859bef", RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.new(0))
  #   end.to raise_error(RubyEventStore::EventDuplicatedInStream)
  # end

  # it 'allows appending to GLOBAL_STREAM explicitly' do
  #   event = SRecord.new(event_id: "df8b2ba3-4e2c-4888-8d14-4364855fa80e")
  #   repository.append_to_stream(event, RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM), RubyEventStore::ExpectedVersion.any)

  #   expect(read_all_streams_forward(repository, :head, 10)).to eq([event])
  # end

  # specify "events not persisted if append failed" do
  #   repository.append_to_stream([
  #     SRecord.new(event_id: SecureRandom.uuid),
  #   ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)

  #   expect do
  #     repository.append_to_stream([
  #       SRecord.new(
  #         event_id: '9bedf448-e4d0-41a3-a8cd-f94aec7aa763'
  #       ),
  #     ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
  #   end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
  #   expect(repository.has_event?('9bedf448-e4d0-41a3-a8cd-f94aec7aa763')).to be_falsey
  # end

  # specify 'reading particular event' do
  #   test_event = SRecord.new(event_id: "941cd8f5-b3f9-47af-b4e4-07f8cea37467")
  #   repository.
  #     append_to_stream(SRecord.new, RubyEventStore::Stream.new("test"), RubyEventStore::ExpectedVersion.none).
  #     append_to_stream(test_event, RubyEventStore::Stream.new("test"), RubyEventStore::ExpectedVersion.new(0))

  #   expect(repository.read_event("941cd8f5-b3f9-47af-b4e4-07f8cea37467")).to eq(test_event)
  # end

  # specify 'reading non-existent event' do
  #   expect do
  #     repository.read_event('72922e65-1b32-4e97-8023-03ae81dd3a27')
  #   end.to raise_error do |err|
  #     expect(err).to be_a(RubyEventStore::EventNotFound)
  #     expect(err.event_id).to eq('72922e65-1b32-4e97-8023-03ae81dd3a27')
  #     expect(err.message).to eq('Event not found: 72922e65-1b32-4e97-8023-03ae81dd3a27')
  #   end
  # end

  # specify 'linking non-existent event' do
  #   skip unless test_link_events_to_stream
  #   expect do
  #     repository.link_to_stream('72922e65-1b32-4e97-8023-03ae81dd3a27', RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.none)
  #   end.to raise_error do |err|
  #     expect(err).to be_a(RubyEventStore::EventNotFound)
  #     expect(err.event_id).to eq('72922e65-1b32-4e97-8023-03ae81dd3a27')
  #     expect(err.message).to eq('Event not found: 72922e65-1b32-4e97-8023-03ae81dd3a27')
  #   end
  # end

  # specify 'read returns enumerator' do
  #   specification = RubyEventStore::Specification.new(repository)
  #   expect(repository.read(specification.result)).to be_kind_of(Enumerator)
  # end

  # specify 'can store arbitrary binary data' do
  #   skip unless test_binary
  #   migrate_to_binary
  #   binary = "\xB0"
  #   expect(binary.valid_encoding?).to eq(false)
  #   binary.force_encoding("binary")
  #   expect(binary.valid_encoding?).to eq(true)

  #   repository.append_to_stream(
  #     event = SRecord.new(data: binary, metadata: binary),
  #     RubyEventStore::Stream.new('stream'),
  #     RubyEventStore::ExpectedVersion.none
  #   )
  # end
end
