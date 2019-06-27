require 'spec_helper'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'
require 'rails_event_store_active_record/event'

module RailsEventStoreActiveRecord
  RSpec.describe PgLinearizedEventRepository do
    include SchemaHelper

    around(:each) do |example|
      begin
        establish_database_connection
        load_database_schema
        example.run
      ensure
        drop_database
      end
    end

    let(:test_race_conditions_auto)  { false }
    let(:test_race_conditions_any)   { true }
    let(:test_binary)                { false }
    let(:test_change)                { true }
    let(:mapper)                     { RubyEventStore::Mappers::NullMapper.new }
    let(:repository)                 { PgLinearizedEventRepository.new }
    let(:specification)              { RubyEventStore::Specification.new(repository, mapper) }

    it_behaves_like :event_repository, PgLinearizedEventRepository

    specify "linearized by lock" do
      begin
        timeout = 2
        exchanger = Concurrent::Exchanger.new
        t = Thread.new do
          ActiveRecord::Base.transaction do
            append_an_event_to_repo
            exchanger.exchange!('locked', timeout)
            exchanger.exchange!('unlocked', timeout)
          end
        end

        exchanger.exchange!('locked', timeout)
        ActiveRecord::Base.transaction do
          execute("SET LOCAL lock_timeout = '1s';")
          expect do
            append_an_event_to_repo
          end.to raise_error(ActiveRecord::LockWaitTimeout)
        end
        exchanger.exchange!('unlocked', timeout)

        expect do
          append_an_event_to_repo
        end.not_to raise_error
      ensure
        t.join
      end
    end

    specify "can publish multiple times" do
      ActiveRecord::Base.transaction do
        expect do
          append_an_event_to_repo
          append_an_event_to_repo
          append_an_event_to_repo
        end.not_to raise_error
      end
    end

    specify "can publish multiple events" do
      ActiveRecord::Base.transaction do
        expect do
          repository.append_to_stream(
            [
              RubyEventStore::SRecord.new,
              RubyEventStore::SRecord.new,
            ],
            RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
            RubyEventStore::ExpectedVersion.any
          )
        end.not_to raise_error
      end
    end

    def cleanup_concurrency_test
      ActiveRecord::Base.connection_pool.disconnect!
    end

    def verify_conncurency_assumptions
      expect(ActiveRecord::Base.connection.pool.size).to eq(5)
    end

    def additional_limited_concurrency_for_auto_check
      positions = RailsEventStoreActiveRecord::EventInStream
        .where(stream: "stream")
        .order("position ASC")
        .map(&:position)
      expect(positions).to eq((0..positions.size-1).to_a)
    end

    private

    def execute(sql)
      ActiveRecord::Base
        .connection
        .execute(sql).each.to_a
    end

    def append_an_event_to_repo
      repository.append_to_stream(
        [RubyEventStore::SRecord.new],
        RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
        RubyEventStore::ExpectedVersion.any
      )
    end

  end if ENV['DATABASE_URL'].include?("postgres")
end
