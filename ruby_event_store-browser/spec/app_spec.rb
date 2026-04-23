# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    specify "accepts experimental_event_types_query parameter" do
      custom_query = ->(event_store) { [] }

      app =
        Browser::App.for(
          event_store_locator: -> { Client.new },
          experimental_event_types_query: custom_query,
        )

      expect(app).not_to be_nil
    end

    specify "uses DefaultQuery when experimental_event_types_query not provided" do
      app = Browser::App.for(event_store_locator: -> { Client.new })

      expect(app).not_to be_nil
    end
  end
end
