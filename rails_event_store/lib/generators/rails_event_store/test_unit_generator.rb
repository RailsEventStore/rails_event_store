# frozen_string_literal: true

require "rails/generators"

module RailsEventStore
  module Generators
    class TestUnitGenerator < Rails::Generators::NamedBase
      source_root File.expand_path(File.join(File.dirname(__FILE__), "../templates"))

      def test_helper
        template "test_helper.erb", "#{bounded_context_name}/test/test_helper.rb"
      end

      def require_bc_test
        template "require_bc_test.erb", "test/#{bounded_context_name}_test.rb"
      end

      private

      def bounded_context_name
        name.underscore
      end
    end
  end
end
