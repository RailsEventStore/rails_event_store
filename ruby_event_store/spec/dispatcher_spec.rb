require 'spec_helper'
require 'ruby_event_store/spec/dispatcher_lint'

module RubyEventStore
  module PubSub

    RSpec.describe Dispatcher do
      it_behaves_like :dispatcher, Dispatcher.new

      specify "does not allow silly subscribers" do
        expect do
          Dispatcher.new.verify(:symbol)
        end.to raise_error(RubyEventStore::InvalidHandler, /\:symbol/)
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
        end.to raise_error(RubyEventStore::InvalidHandler)
      end
    end

  end
end