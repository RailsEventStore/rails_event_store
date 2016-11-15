require 'spec_helper'

RSpec.describe RailsEventStore do
  after :each do
    RailsEventStore.event_repository = RailsEventStoreActiveRecord::EventRepository.new
  end

  it { expect(RailsEventStore.event_repository).to be_instance_of(RailsEventStoreActiveRecord::EventRepository) }

  describe '.adapter=' do
    it { expect{ RailsEventStore.event_repository = nil }.to raise_error(ArgumentError) }

    it 'when passing an object' do
      adapter = Object.new
      RailsEventStore::event_repository = adapter

      expect(RailsEventStore::event_repository).to eq adapter
    end
  end
end
