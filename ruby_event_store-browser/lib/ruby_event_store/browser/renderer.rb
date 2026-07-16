# frozen_string_literal: true

require "erb"
require "json"

module RubyEventStore
  module Browser
    class Renderer
      VIEWS_ROOT = File.expand_path("views", __dir__).freeze

      class Context
        include ERB::Util
        alias_method :h, :html_escape

        def initialize(renderer, locals)
          @_renderer = renderer
          locals.each { |k, v| define_singleton_method(k) { v } }
        end

        def render(template, **locals)
          @_renderer.render(template, **locals)
        end

        def safe_json(value)
          if value.is_a?(Float) && value.infinite? && value.positive?
            '"Infinity"'
          elsif value.is_a?(Float) && value.infinite?
            '"-Infinity"'
          elsif value.is_a?(Float) && value.nan?
            '"NaN"'
          elsif value.is_a?(Float) && value == value.to_i
            value.to_i.to_s
          elsif value.is_a?(Hash)
            "{#{value.map { |k, v| "#{k.to_json}:#{safe_json(v)}" }.join(",")}}"
          elsif value.is_a?(Array)
            "[#{value.map { |v| safe_json(v) }.join(",")}]"
          else
            value.to_json
          end
        end

        def get_binding
          binding
        end
      end

      def render(template, **locals)
        path = File.join(VIEWS_ROOT, "#{template}.html.erb")
        context = Context.new(self, locals)
        ERB.new(File.read(path), trim_mode: "-").result(context.get_binding)
      end
    end
  end
end
