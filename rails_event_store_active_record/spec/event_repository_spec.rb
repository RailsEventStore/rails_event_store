require 'spec_helper'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'

module RailsEventStoreActiveRecord
  describe EventRepository do
    before do
      ActiveRecord::Base.logger = Logger.new(STDOUT)
    end
    let(:test_race_conditions_auto) { true }
    let(:test_race_conditions_any)  { true }
    it_behaves_like :event_repository, EventRepository

    def cleanup_concurrency_test
      ActiveRecord::Base.connection_pool.disconnect!
    end

    def verify_conncurency_assumptions
      expect(ActiveRecord::Base.connection.pool.size).to eq(5)
    end

    def additional_limited_concurrency_for_auto_check
      positions = RailsEventStoreActiveRecord::EventInStream.
        where(stream: "stream").
        order("position ASC").
        map(&:position)
      expect(positions).to eq((0..positions.size-1).to_a)
    end

    specify 'initialize with adapter' do
      repository = EventRepository.new
      expect(repository.adapter).to eq(Event)
    end

    specify 'provide own event implementation' do
      CustomEvent = Class.new(ActiveRecord::Base)
      repository = EventRepository.new(adapter: CustomEvent)
      expect(repository.adapter).to eq(CustomEvent)
    end
  end
end
