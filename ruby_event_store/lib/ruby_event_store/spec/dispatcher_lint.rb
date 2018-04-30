RSpec.shared_examples :dispatcher do |dispatcher|
  let(:event) { instance_double(::RubyEventStore::Event) }
  let(:serialized_event) { instance_double(::RubyEventStore::SerializedRecord)  }
  let(:handler) { HandlerClass.new }

  specify "calls subscribed instance" do
    expect(handler).to receive(:call).with(event)
    dispatcher.call(handler, event, serialized_event)
  end

  specify "calls subscribed class" do
    expect(HandlerClass).to receive(:new).and_return(handler)
    expect(handler).to receive(:call).with(event)
    dispatcher.call(HandlerClass, event, serialized_event)
  end

  specify "allows callable classes and instances" do
    expect do
      dispatcher.verify(HandlerClass)
    end.not_to raise_error
    expect do
      dispatcher.verify(HandlerClass.new)
    end.not_to raise_error
    expect do
      dispatcher.verify(Proc.new{ "yo" })
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
