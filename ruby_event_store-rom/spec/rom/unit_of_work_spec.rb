require 'spec_helper'

module RubyEventStore::ROM
  RSpec.describe UnitOfWork do
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

    specify '#call to throw an exeption' do
      expect{subject.call(gateway: nil) {}}.to raise_error(KeyError)
    end
  end
end
