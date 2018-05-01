require 'spec_helper'

module RubyEventStore::ROM
  RSpec.describe Env do
    include SchemaHelper

    around(:each) do |example|
      begin
        establish_database_connection
        load_database_schema
        example.run
      ensure
        drop_database
      end
    end

    let(:container) { ROM.container }
    let(:instance) { Env.new(container) }

    specify '#container gives access to ROM container' do
      expect(instance.container).to be_a(::ROM::Container)
    end

    specify '#logger gives access to Logger' do
      expect(instance.logger).to be_a(Logger)
    end
  end
end
