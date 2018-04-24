require 'spec_helper'

module RubyEventStore::ROM
  RSpec.describe SQL::SpecHelper do
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

    specify '#env gives access to ROM container' do
      expect(subject.env.container).to be_a(::ROM::Container)
    end
  end
end
