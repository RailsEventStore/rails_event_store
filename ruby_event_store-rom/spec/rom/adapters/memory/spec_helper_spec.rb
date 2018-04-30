require 'spec_helper'
require 'ruby_event_store/rom/memory'
require 'ruby_event_store/spec/rom/spec_helper_lint'

module RubyEventStore::ROM::Memory
  RSpec.describe SpecHelper do
    let(:rom_helper) { SpecHelper.new }

    it_behaves_like :rom_spec_helper, SpecHelper

    specify '#has_connection_pooling? is enabled for Memory adapter' do
      expect(subject.has_connection_pooling?).to eq(true)
    end

    specify '#connection_pool_size is 5' do
      expect(subject.connection_pool_size).to eq(5)
    end
  end
end
