require 'spec_helper'

module RubyEventStore
  module ROM
  RSpec.describe Env do
    let(:rom_container) { ::ROM.container }
    let(:instance) { Env.new(rom_container) }

    specify '#container gives access to ROM container' do
      expect(instance.rom_container).to be_a(::ROM::Container)
    end

    specify '#logger gives access to Logger' do
      expect(instance.logger).to be_a(Logger)
    end
  end
  end
end
