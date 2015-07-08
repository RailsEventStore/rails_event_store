require 'spec_helper'

module RailsEventStore
  describe Client do

    let(:instance) { described_class.new }

    it { expect(instance.repository).to eq(RailsEventStore::Repository.backend) }

  end
end
