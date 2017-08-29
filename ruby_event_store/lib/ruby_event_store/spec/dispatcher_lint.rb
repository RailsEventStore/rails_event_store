RSpec.shared_examples :dispatcher do |dispatcher|
  specify "calls subscribed handler" do
    handler = double(:handler)
    event   = instance_double(::RubyEventStore::Event)

    expect(handler).to receive(:call).with(event)
    dispatcher.(handler, event)
  end
end
