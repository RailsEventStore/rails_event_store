require 'spec_helper'
require 'ruby_event_store/spec/dispatcher_lint'

module RubyEventStore
  module PubSub

    RSpec.describe Dispatcher do
      it_behaves_like :dispatcher, Dispatcher.new

      specify "does not allow silly subscribers" do
        expect do
          Dispatcher.new.verify(:symbol)
        end.to raise_error(RubyEventStore::InvalidHandler, /^#call method not found in \:symbol/)

        expect do
          Dispatcher.new.verify(Object.new)
        end.to raise_error(RubyEventStore::InvalidHandler, /Object/)
      end

      specify "does not allow class without instance method #call" do
        klass = Class.new do
        end
        expect do
          Dispatcher.new.verify(klass)
        end.to raise_error(RubyEventStore::InvalidHandler)
      end

      specify "does not allow class without constructor requiring arguments" do
        klass = Class.new do
          def initialize(something)
            @something = something
          end
        end
        expect do
          Dispatcher.new.verify(klass)
        end.to raise_error(RubyEventStore::InvalidHandler, /Class/)
      end
    end

  end
end