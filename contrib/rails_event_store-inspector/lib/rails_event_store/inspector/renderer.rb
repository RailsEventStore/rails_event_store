# frozen_string_literal: true

require "erb"

module RailsEventStore
  module Inspector
    class Renderer
      VIEWS_ROOT = File.expand_path("views", __dir__).freeze

      class Context
        include ERB::Util
        alias_method :h, :html_escape

        def initialize(renderer, locals)
          @_renderer = renderer
          locals.each { |name, value| define_singleton_method(name) { value } }
        end

        def render(template, **locals)
          @_renderer.render(template, **locals)
        end

        def get_binding
          binding
        end
      end

      def render(template, **locals)
        ERB.new(read(template), trim_mode: "-").result(Context.new(self, locals).get_binding)
      end

      private

      def read(template)
        cache[template] ||= File.read(path_for(template))
      end

      def cache
        @cache ||= {}
      end

      def path_for(template)
        File.join(VIEWS_ROOT, "#{template}.html.erb")
      end
    end
  end
end
