require 'spec_helper'
require 'ruby_event_store/spec/dispatcher_lint'

module RailsEventStore
  RSpec.describe Dispatcher do
    it_behaves_like :dispatcher, Dispatcher.new
  end
end
