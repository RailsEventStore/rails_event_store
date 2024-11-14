# frozen_string_literal: true

module RubyEventStore
  module Browser
    class GemSource
      attr_reader :path

      def initialize(load_path)
        @path =
          load_path
            .select { |entry| String === entry }
            .find do |entry|
              entry.match? %r{ruby_event_store-browser(?:-\d+\.\d+\.\d+)?/lib\z}
            end
      end

      def version
        if from_rubygems?
          path.split("/").fetch(-2).split("-").last
        elsif from_git?
          path.split("/").fetch(-3).split("-").last
        end
      end

      def from_rubygems?
        path.match? %r{/gems/ruby_event_store-browser-\d+\.\d+\.\d+/lib\z}
      end

      def from_git?
        path.match? %r{/bundler/gems/rails_event_store-[a-z0-9]{12}/ruby_event_store-browser/lib\z}
      end
    end
  end
end
