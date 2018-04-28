require 'spec_helper'

module RubyEventStore::ROM
  RSpec.describe UnitOfWork do
    subject { UnitOfWork.new(rom: rom_helper.env) }

    let(:rom_helper) { Memory::SpecHelper.new }

    around(:each) do |example|
      rom_helper.run_lifecycle { example.run }
    end

    specify '#env gives access to ROM container' do
      expect(subject.env.container).to be_a(::ROM::Container)
    end

    specify '#call to throw an exeption' do
      expect{subject.call(gateway: nil) {}}.to raise_error(KeyError)
    end
  end
end
