require 'spec_helper'

module RubyEventStoreRomSql
  RSpec.describe 'no warnings', mutate: false do
    specify do
      expect(ruby_event_store_rom_sql_warnings).to eq([])
    end

    def ruby_event_store_rom_sql_warnings
      warnings.select { |w| w =~ %r{lib/ruby_event_store_rom_sql} }
    end

    def warnings
      `ruby -Ilib -w lib/ruby_event_store_rom_sql.rb 2>&1`.split("\n")
    end
  end
end
