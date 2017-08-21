RSpec.shared_examples :dispatcher do |dispatcher|
  specify "calls subscribed handler" do
    handler = double(:handler)
    event   = instance_double(RubyEventStore::Event)

    expect(handler).to receive(:call).with(event)
    dispatcher.(handler, event)
  end

  specify "error when invalid subscriber passed" do
    handler = double(:handler)
    event   = instance_double(RubyEventStore::Event)

    expect { dispatcher.(handler, event) }.to raise_error(RubyEventStore::MethodNotDefined,
      "#call method not found in RSpec::Mocks::Double subscriber. Are you sure it is a valid subscriber?")
  end
end
