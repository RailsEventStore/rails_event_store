require 'spec_helper'

module RailsEventStore
  describe Actions::DeleteStreamEvents do

    let(:repository)  { EventInMemoryRepository.new }
    let(:service)     { Actions::DeleteStreamEvents.new(repository) }
    let(:stream_name) { 'stream_name' }

    before(:each) do
      repository.reset!
    end

    specify 'raise exception if stream name is incorrect' do
      expect { service.call(nil) }.to raise_error(IncorrectStreamData)
      expect { service.call('') }.to raise_error(IncorrectStreamData)
    end

    specify 'create successfully delete streams events' do
      prepare_events_in_store('test_1')
      prepare_events_in_store('test_2')
      expect(repository.db.length).to eq 8
      service.call('test_2')
      expect(repository.db.length).to eq 4
      repository.db.each do |event|
        expect(event.stream).to eq 'test_1'
      end
    end

    private

    def prepare_events_in_store(stream_name)
      4.times do |index|
        event_data = {event_type: 'OrderCreated',
                      data: {data: 'sample'},
                      event_id: index}
        create_event(event_data, stream_name)
      end
    end

    def create_event(event_data, stream_name)
      Actions::AppendEventToStream.new(repository).call(stream_name, event_data, nil)
    end

  end
end
