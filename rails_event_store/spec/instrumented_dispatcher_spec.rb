require 'spec_helper'
require 'ruby_event_store/spec/dispatcher_lint'

module RailsEventStore
  RSpec.describe InstrumentedDispatcher do
    it_behaves_like :dispatcher, InstrumentedDispatcher.new
  end
end
