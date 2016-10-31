require 'spec_helper'

RSpec.describe RailsEventStore::Repository do

  subject(:adapter) { described_class.adapter }

  after :all do
    described_class.adapter = :active_record
  end

  describe '.adapter=' do

    context 'when passing nil' do

      before do
        described_class.adapter = nil
      end

      it { is_expected.to eq(nil) }

    end

    context 'when passing a string' do

      context 'which module exists' do

        before do
          described_class.adapter = 'active_record'
        end

        it { is_expected.to be_a(RailsEventStoreActiveRecord::EventRepository) }

      end

      context 'when passing a symbol' do

        context 'which module exists' do

          before do
            described_class.adapter = :active_record
          end

          it { is_expected.to be_a(RailsEventStoreActiveRecord::EventRepository) }

        end

      end

    end

    context 'when passing an object' do

      let(:adapter_class) do
        Class.new
      end
      let(:adapter) { adapter_class.new }

      before do
        described_class.adapter = adapter
      end

      it { is_expected.to eq(adapter) }

    end

  end

end
