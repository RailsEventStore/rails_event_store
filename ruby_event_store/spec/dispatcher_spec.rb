require 'spec_helper'
require 'ruby_event_store/spec/dispatcher_lint'

module RubyEventStore
  module PubSub
    RSpec.describe Dispatcher do
      it_behaves_like :dispatcher, Dispatcher.new
    end
  end
end
