require 'spec_helper'

module RailsEventStore
  describe Client do

    specify 'initialize proper adapter type' do
      client = Client.new
      expect(client.repository).to be_a Repositories::EventRepository
    end

  end
end
