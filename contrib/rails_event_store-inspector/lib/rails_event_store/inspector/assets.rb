# frozen_string_literal: true

module RailsEventStore
  module Inspector
    module Assets
      ROOT = File.expand_path("assets", __dir__).freeze

      class << self
        def css
          @css ||= read("panel.css")
        end

        def js
          @js ||= read("panel.js")
        end

        private

        def read(name)
          File.read(File.join(ROOT, name))
        end
      end
    end
  end
end
