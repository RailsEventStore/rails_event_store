# frozen_string_literal: true

require 'rails/generators'

module BoundedContext
  module Generators
    class BoundedContextGenerator < Rails::Generators::NamedBase
      source_root File.expand_path(File.join(File.dirname(__FILE__), '../templates'))
      hook_for :test_framework

      def create_bounded_context
        create_file "#{bounded_context_name}/lib/#{bounded_context_name}/.keep"

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
  end
end
