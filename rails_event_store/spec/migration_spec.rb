# frozen_string_literal: true

require "spec_helper"

module RailsEventStore
  ::RSpec.describe "Migration" do
    specify do
      expect(Rails::Generators.public_namespaces).to include("rails_event_store_active_record:migration")
    end
  end
end
