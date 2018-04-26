require 'spec_helper'
require 'ruby_event_store/rom/sql'

module RubyEventStore::ROM::SQL
  RSpec.describe SpecHelper do
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
