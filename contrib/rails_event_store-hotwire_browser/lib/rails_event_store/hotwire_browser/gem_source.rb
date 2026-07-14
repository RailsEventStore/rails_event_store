# frozen_string_literal: true

module RailsEventStore
  module HotwireBrowser
    class GemSource
      attr_reader :path

      def initialize(load_path)
        @path =
          load_path
            .select { |entry| String === entry }
            .find { |entry| entry.match? %r{rails_event_store-hotwire_browser(?:-\d+\.\d+\.\d+)?/lib\z} }
      end

      def version
        if from_rubygems?
          path.split("/").fetch(-2).split("-").last
        elsif from_git?
          path.split("/").fetch(-4).split("-").last
        end
      end

      def from_rubygems?
        path.match? %r{/gems/rails_event_store-hotwire_browser-\d+\.\d+\.\d+/lib\z}
      end

      def from_git?
        path.match? %r{/bundler/gems/rails_event_store-[a-z0-9]{12}/contrib/rails_event_store-hotwire_browser/lib\z}
      end
    end
  end
end
