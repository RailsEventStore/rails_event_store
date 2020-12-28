# frozen_string_literal: true

require 'rails/generators'

module BoundedContext
  module Generators
    class RspecGenerator < Rails::Generators::NamedBase
      source_root File.expand_path(File.join(File.dirname(__FILE__), '../templates'))

      def spec_helper
        template "spec_helper.rb", "#{bounded_context_name}/spec/spec_helper.rb"
      end

      def bc_spec
        template "bc_spec.rb", "#{bounded_context_name}/spec/#{bounded_context_name}_spec.rb"
      end

      def require_bc_spec
        template "require_bc_spec.rb", "spec/#{bounded_context_name}_spec.rb"
      end

      private

      def bounded_context_namespace
        name.camelize
      end

      def bounded_context_name
        name.underscore
      end
    end
  end
end
