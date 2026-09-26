# frozen_string_literal: true

require "erb"
require_relative "renderer"
require_relative "tree"
require_relative "assets"

module RailsEventStore
  module Inspector
    class Panel
      def initialize(entries, links = BrowserLinks.new(nil), nonce: nil)
        @tree = Tree.new(entries, links)
        @nonce = nonce
      end

      def to_html
        style + shell + script
      end

      def to_fragment
        renderer.render(
          "fragment",
          groups: @tree.groups,
          requests: pluralize(@tree.groups.size, "request"),
          reset_path: Inspector::RESET_PATH,
        )
      end

      def event_count
        @tree.event_count
      end

      private

      def renderer
        @renderer ||= Renderer.new
      end

      def shell
        renderer.render(
          "shell",
          event_count: event_count,
          panel_path: Inspector::PANEL_PATH,
          count_header: Inspector::COUNT_HEADER,
        )
      end

      def style
        %(<style id="res-inspector-style"#{nonce_attribute}>#{Assets.css}</style>\n)
      end

      def script
        %(<script#{nonce_attribute}>#{Assets.js}</script>\n)
      end

      def nonce_attribute
        @nonce ? %( nonce="#{ERB::Util.html_escape(@nonce)}") : ""
      end

      def pluralize(count, noun)
        "#{count} #{noun}#{"s" unless count == 1}"
      end
    end
  end
end
