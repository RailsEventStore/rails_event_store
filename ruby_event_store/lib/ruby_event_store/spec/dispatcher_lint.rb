RSpec.shared_examples :dispatcher do |dispatcher|
  specify "calls subscribed instance" do
    handler = HandlerClass.new
    event   = instance_double(::RubyEventStore::Event)

    expect(handler).to receive(:call).with(event)
    dispatcher.(handler, event)
  end

  specify "calls subscribed class" do
    event   = instance_double(::RubyEventStore::Event)

    expect(HandlerClass).to receive(:new).and_return( h = HandlerClass.new )
    expect(h).to receive(:call).with(event)
    dispatcher.(HandlerClass, event)
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
