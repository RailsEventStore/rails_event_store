require 'spec_helper'

module RailsEventStore
  describe Client do

    specify 'initialize proper adapter type' do
      repository = Repositories::EventRepository.new
      expect(repository.adapter.model_name.name).to eq 'RailsEventStore::EventEntity'
    end

  end
end
