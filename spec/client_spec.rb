require 'spec_helper'

module RailsEventStore
  describe Client do

    specify 'initialize proper adapter type' do
      client = Client.new
      expect(client.repository).to eq(Repository.backend)
    end

  end
end
