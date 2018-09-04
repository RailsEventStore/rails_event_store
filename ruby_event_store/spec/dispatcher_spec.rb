require 'spec_helper'
require 'ruby_event_store/spec/dispatcher_lint'

module RubyEventStore
  module PubSub
    RSpec.describe Dispatcher do
      it_behaves_like :dispatcher, Dispatcher.new
      let(:event) { instance_double(::RubyEventStore::Event) }
      let(:serialized_event) { instance_double(::RubyEventStore::SerializedRecord)  }
      let(:handler) { HandlerClass.new }

      specify "does not allow silly subscribers" do
        expect do
          Dispatcher.new.verify(:symbol)
        end.to raise_error(RubyEventStore::InvalidHandler, /:symbol/)

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
        end.to raise_error(RubyEventStore::InvalidHandler, /^#call method not found in #<Class/)
      end

      specify "calls subscribed instance" do
        expect(handler).to receive(:call).with(event)
        Dispatcher.new.call(handler, event, serialized_event)
      end

      specify "calls subscribed class" do
        expect(HandlerClass).to receive(:new).and_return(handler)
        expect(handler).to receive(:call).with(event)
        Dispatcher.new.call(HandlerClass, event, serialized_event)
      end

      specify "allows callable classes and instances" do
        expect do
          Dispatcher.new.verify(HandlerClass)
        end.not_to raise_error
        expect do
          Dispatcher.new.verify(HandlerClass.new)
        end.not_to raise_error
        expect do
          Dispatcher.new.verify(Proc.new{ "yo" })
        end.not_to raise_error
      end

      private

      class HandlerClass
        @@received = nil
        def self.received
          @@received
        end
        def call(event)
          @@received = event
        end
      end
    end
  end
end
