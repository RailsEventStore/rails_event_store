RSpec.shared_examples :dispatcher do |dispatcher|
  specify "calls subscribed handler" do
    handler = spy
    event   = instance_double(RubyEventStore::Event)
    dispatcher.(handler, event)

    expect(handler).to have_received(:call).with(event)
  end

  specify "error when invalid subscriber passed" do
    handler = double
    event   = instance_double(RubyEventStore::Event)

    expect { dispatcher.(handler, event) }.to raise_error(RubyEventStore::MethodNotDefined,
      "#call method not found in RSpec::Mocks::Double subscriber. Are you sure it is a valid subscriber?")
  end
end
