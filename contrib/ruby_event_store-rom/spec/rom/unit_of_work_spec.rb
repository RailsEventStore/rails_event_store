require 'spec_helper'

module RubyEventStore
  module ROM
    RSpec.describe UnitOfWork do
      let(:rom_helper)   { SpecHelper.new }
      let(:env)          { rom_helper.env }
      let(:unit_of_work) { UnitOfWork.new(rom: env) }

      around(:each) do |example|
        rom_helper.run_lifecycle { example.run }
      end

      specify '#env gives access to ROM container' do
        expect(unit_of_work.env.rom_container).to be_a(::ROM::Container)
      end

      specify '#call to throw an exception' do
        expect { unit_of_work.call(gateway: nil) {} }.to raise_error(KeyError)
      end

      specify '#env is the instance we specified' do
        expect(unit_of_work.env).to eq(env)
      end

      specify '#env is the global instance' do
        RubyEventStore::ROM.env = SpecHelper.new.env

        expect(UnitOfWork.new.env).to     eq(RubyEventStore::ROM.env)
        expect(UnitOfWork.new.env).not_to eq(unit_of_work.env)
        expect(unit_of_work.env).not_to   eq(RubyEventStore::ROM.env)

        RubyEventStore::ROM.env = nil
      end
    end
  end
end
