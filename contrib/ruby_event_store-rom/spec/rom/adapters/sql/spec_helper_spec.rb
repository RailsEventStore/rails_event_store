require 'spec_helper'
require 'ruby_event_store/rom/sql'
require 'ruby_event_store/spec/rom/spec_helper_lint'

module RubyEventStore
  module ROM
  module SQL
  RSpec.describe SpecHelper do
    let(:rom_helper) { SpecHelper.new }

    it_behaves_like :rom_spec_helper, SpecHelper

    specify '#has_connection_pooling? is disabled for SQLite' do
      skip unless rom_helper.gateway_type?(:sqlite)

      expect(rom_helper.has_connection_pooling?).to eq(false)
    end

    specify '#connection_pool_size is 1 when has_connection_pooling? is false' do
      expect(subject.connection_pool_size).to eq(1) unless rom_helper.has_connection_pooling?
    end

    specify '#connection_pool_size is 5 when has_connection_pooling? is true' do
      expect(subject.connection_pool_size).to eq(5) if rom_helper.has_connection_pooling?
    end
  end
  end
  end
end
