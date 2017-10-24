require 'rails/generators'

module BoundedContext
  module Generators
    class BoundedContextGenerator < Rails::Generators::NamedBase
      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
      hook_for :test_framework

      def create_bounded_context
        template "module.rb", "#{bounded_context_name}/lib/#{bounded_context_name}.rb"

        application do
          "config.paths.add '#{bounded_context_name}/lib', eager_load: true"
        end
      end

      private

      def bounded_context_namespace
        name.camelize
      end

      def bounded_context_name
        name.underscore
      end
    end

    class RspecGenerator < Rails::Generators::NamedBase
      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

      def spec_helper
        template "spec_helper.rb", "#{bounded_context_name}/spec/spec_helper.rb"
      end

      private

      def bounded_context_name
        name.underscore
      end
    end

    class TestUnitGenerator < Rails::Generators::NamedBase
      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

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
