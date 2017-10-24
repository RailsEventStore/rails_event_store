require 'rails/generators'

module BoundedContext
  module Generators
    class RspecGenerator < Rails::Generators::NamedBase
      source_root File.expand_path(File.join(File.dirname(__FILE__), '../../templates'))

      def spec_helper
        template "spec_helper.rb", "#{bounded_context_name}/spec/spec_helper.rb"
      end

      private

      def bounded_context_name
        name.underscore
      end
    end
  end
end
