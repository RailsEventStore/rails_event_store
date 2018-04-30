require 'spec_helper'
require 'ruby_event_store/rom/sql'
require 'ruby_event_store/spec/rom/spec_helper_lint'

module RubyEventStore::ROM::SQL
  RSpec.describe SpecHelper do
    let(:rom_helper) { SpecHelper.new }

    it_behaves_like :rom_spec_helper, SpecHelper

    specify '#has_connection_pooling? is disabled for SQLite' do
      helper = SpecHelper.new('sqlite:db.sqlite3')

      expect(helper.has_connection_pooling?).to eq(false)
    end

    specify '#connection_pool_size is 1' do
      expect(subject.connection_pool_size).to eq(1)
    end
  end
end
