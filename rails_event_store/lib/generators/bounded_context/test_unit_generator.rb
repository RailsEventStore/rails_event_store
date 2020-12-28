# frozen_string_literal: true

require 'rails/generators'

module BoundedContext
  module Generators
    class TestUnitGenerator < Rails::Generators::NamedBase
      source_root File.expand_path(File.join(File.dirname(__FILE__), '../templates'))

      def test_helper
        template "test_helper.rb", "#{bounded_context_name}/test/test_helper.rb"
      end

      private

      def bounded_context_name
        name.underscore
      end
    end
  end
end
