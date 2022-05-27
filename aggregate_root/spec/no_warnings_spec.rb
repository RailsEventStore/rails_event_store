# frozen_string_literal: true

require "spec_helper"

module AggregateRoot
  RSpec.describe "no warnings" do
    specify { expect(aggregate_root_warnings).to eq([]) }

    def aggregate_root_warnings
      warnings.select { |w| w =~ %r{lib/aggregate_root} }
    end

    def warnings
      `ruby -Ilib -w lib/aggregate_root.rb 2>&1`.split("\n")
    end
  end
end
