# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Transformations
    RSpec.describe "no warnings", mutant: false do
      specify { expect(ruby_event_store_transformations_warnings).to eq([]) }

      def ruby_event_store_transformations_warnings
        warnings.select { |w| w =~ %r{lib/ruby_event_store/transformations} }
      end

      def warnings
        `ruby -Ilib -w lib/ruby_event_store/transformations.rb 2>&1`.split("\n")
      end
    end
  end
end
