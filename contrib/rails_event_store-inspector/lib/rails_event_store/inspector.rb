# frozen_string_literal: true

require_relative "inspector/version"
require_relative "inspector/configuration"
require_relative "inspector/scope"
require_relative "inspector/buffer"
require_relative "inspector/frames"
require_relative "inspector/collector"
require_relative "inspector/browser_links"
require_relative "inspector/assets"
require_relative "inspector/renderer"
require_relative "inspector/tree"
require_relative "inspector/panel"
require_relative "inspector/insertion"
require_relative "inspector/middleware"

module RailsEventStore
  module Inspector
    RESET_PATH = "/__res_inspector/reset"
    PANEL_PATH = "/__res_inspector/panel"
    COUNT_HEADER = "X-Res-Inspector-Count"

    ACTIVE = :res_inspector_active
    SCOPE = :res_inspector_scope

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def install?
        configuration.install?
      end

      def active?
        Thread.current[ACTIVE] == true
      end

      def scope
        Thread.current[SCOPE]
      end

      def buffer
        @buffer ||= Buffer.new
      end

      def browser_links
        @browser_links ||= BrowserLinks.from_rails
      end

      def reset_browser_links!
        @browser_links = nil
      end
    end
  end
end

require_relative "inspector/railtie" if defined?(::Rails::Railtie)
