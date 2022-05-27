require "spec_helper"

module RubyEventStore
  ::RSpec.describe "no warnings" do
    specify { expect(ruby_event_store_rspec_warnings).to eq([]) }

    def ruby_event_store_rspec_warnings
      warnings.select { |w| w =~ %r{lib/ruby_event_store/rspec} }
    end

    def warnings
      `ruby -Ilib -w lib/ruby_event_store/rspec.rb 2>&1`.split("\n")
    end
  end
end
