require "spec_helper"

module RubyEventStore
  module Protobuf
    ::RSpec.describe "no warnings", mutant: false do
      specify { expect(ruby_event_store_protobuf_warnings).to eq([]) }

      def ruby_event_store_protobuf_warnings
        warnings.select { |w| w =~ %r{lib/ruby_event_store/protobuf} }
      end

      def warnings
        `ruby -Ilib -w lib/ruby_event_store/protobuf.rb 2>&1`.split("\n")
      end
    end
  end
end
