require 'spec_helper'

describe RailsEventStore::Repository do

  describe '.backend=' do

    context 'active_record' do

      before do
        described_class.backend = :active_record
      end

      it { expect(described_class.backend).to be_a(RailsEventStore::Repositories::ActiveRecord::EventRepository) }

    end

    context 'mongoid' do

      before do
        described_class.backend = :mongoid
      end

      it { expect(described_class.backend).to be_a(RailsEventStore::Repositories::Mongoid::EventRepository) }

    end

  end

end
