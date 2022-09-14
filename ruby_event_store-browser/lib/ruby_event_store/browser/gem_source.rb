# frozen_string_literal: true

module RubyEventStore
  module Browser
    class GemSource
      attr_reader :path

      def initialize(load_path)
        @path = load_path.find { |x| x.match? %r{ruby_event_store-browser(-\d\.\d\.\d)?/lib\Z} }
      end

      def version
        if from_rubygems?
          path.split("/")[-2].split("-")[-1]
        elsif from_git?
          path.split("/")[-3].split("-")[-1]
        else
          nil
        end
      end

      def from_rubygems?
        path.match %r{/gems/ruby_event_store-browser-\d\.\d\.\d/lib\Z}
      end

      def from_git?
        path.match %r{/bundler/gems/rails_event_store-[a-z0-9]{12}/ruby_event_store-browser/lib\Z}
      end
    end
  end
end
