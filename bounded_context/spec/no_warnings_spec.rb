# frozen_string_literal: true

require 'spec_helper'

module BoundedContext
  RSpec.describe 'no warnings' do
    specify do
      expect(bounded_context_warnings).to eq([])
    end

    def bounded_context_warnings
      warnings.select { |w| w =~ %r{lib/bounded_context} }
    end

    def warnings
      `ruby -Ilib -w lib/bounded_context.rb 2>&1`.split("\n")
    end
  end
end
