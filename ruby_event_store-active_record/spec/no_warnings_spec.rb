require "spec_helper"

module RubyEventStore
module ActiveRecord
  RSpec.describe "no warnings", mutant: false do
    specify { expect(rails_event_store_active_record_warnings).to eq([]) }

    def rails_event_store_active_record_warnings
      warnings.select { |w| w =~ %r{lib/ruby_event_store-active_record} }
    end

    def warnings
      `ruby -Ilib -w lib/ruby_event_store-active_record.rb 2>&1`.split("\n")
    end
  end
end
end