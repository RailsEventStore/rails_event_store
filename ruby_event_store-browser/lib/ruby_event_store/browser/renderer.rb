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

        def json_tree(value)
          append_json_value(+"", value)
        end

        def get_binding
          binding
        end

        private

        def append_json_value(html, value)
          if value.is_a?(Hash) && !value.empty?
            html << '{<ul class="list-none ml-[26px] pl-0">'
            value.sort_by { |key, _| key.to_s }.each do |key, child|
              html << '<li class="relative"><span class="font-bold">' << h(key) << "</span>: "
              append_json_value(html, child)
              html << ",</li>"
            end
            html << "</ul>}"
          elsif value.is_a?(Array) && !value.empty?
            html << '[<ul class="list-none ml-[26px] pl-0">'
            value.each do |child|
              html << '<li class="relative">'
              append_json_value(html, child)
              html << ",</li>"
            end
            html << "</ul>]"
          else
            color =
              case value
              when String then "text-[green]"
              when Numeric then "text-[blue]"
              when true, false then "text-[firebrick]"
              when nil then "text-[gray]"
              else "text-gray-800"
              end
            html << '<span class="whitespace-pre ' << color << '">' << h(safe_json(value)) << "</span>"
          end
          html
        end
      end

      def initialize(views_roots = [VIEWS_ROOT])
        @views_roots = views_roots
      end

      def render(template, **locals)
        context = Context.new(self, locals)
        ERB.new(File.read(template_path(template)), trim_mode: "-").result(context.get_binding)
      end

      private

      def template_path(template)
        @views_roots.map { |root| File.join(root, "#{template}.html.erb") }.find { |path| File.exist?(path) } ||
          raise(ArgumentError, "Template not found: #{template}")
      end
    end
  end
end
