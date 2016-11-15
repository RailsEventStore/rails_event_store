require 'spec_helper'

RSpec.describe RailsEventStore::Repository do
  after :each do
    RailsEventStore::Repository.adapter = RailsEventStoreActiveRecord::EventRepository.new
  end

  it { expect(RailsEventStore::Repository.adapter).to be_instance_of(RailsEventStoreActiveRecord::EventRepository) }

  describe '.adapter=' do
    it { expect{ RailsEventStore::Repository.adapter = nil }.to raise_error(ArgumentError) }

    it 'when passing an object' do
      adapter = Object.new
      RailsEventStore::Repository.adapter = adapter

      expect(RailsEventStore::Repository.adapter).to eq adapter
    end
  end
end
