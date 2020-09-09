require 'spec_helper'

module RubyEventStore
  module ROM
  RSpec.describe 'no warnings', mutant: false do
    specify do
      expect(ruby_event_store_rom_warnings).to eq([])
    end

    def ruby_event_store_rom_warnings
      warnings.select { |w| w =~ %r{lib/ruby_event_store-rom} }
    end

    def warnings
      `ruby -Ilib -w lib/ruby_event_store-rom.rb 2>&1`.split("\n")
    end
  end
  end
end
