RSpec.shared_examples :dispatcher do |dispatcher|
  specify "calls subscribed handler" do
    handler = double(:handler)
    event   = instance_double(::RubyEventStore::Event)

    expect(handler).to receive(:call).with(event)
    dispatcher.(handler, event)
  end

  specify "returns callable proxy" do
    event   = instance_double(::RubyEventStore::Event)

    handler = dispatcher.proxy_for(HandlerClass)
    expect(handler).to receive(:call).with(event).and_call_original
    dispatcher.(handler, event)
    expect(HandlerClass.received).to eq(event)
  end

  specify "fails to build proxy when no call method defined on class" do
    message = "#call method not found " +
      "in String subscriber." +
      " Are you sure it is a valid subscriber?"

    expect { dispatcher.proxy_for(String) }.to raise_error(::RubyEventStore::InvalidHandler, message)
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
