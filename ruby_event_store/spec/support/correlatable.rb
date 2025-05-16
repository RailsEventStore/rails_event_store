# frozen_string_literal: true

RSpec.shared_examples "correlatable" do |factory|
  specify "correlation_id && causation_id" do
    e0 = factory.call(event_id: "doh")
    expect(e0.event_id).to eq("doh")
    expect(e0.correlation_id).to be_nil
    expect(e0.causation_id).to be_nil

    e1 = factory.call(event_id: "yay")
    e1.correlate_with(e0)
    expect(e1.event_id).to eq("yay")
    expect(e1.correlation_id).to eq("doh")
    expect(e1.causation_id).to eq("doh")

    e2 = factory.call(event_id: "jeb")
    e2.correlate_with(e1)
    expect(e2.event_id).to eq("jeb")
    expect(e2.correlation_id).to eq("doh")
    expect(e2.causation_id).to eq("yay")

    event = factory.call(event_id: "mem", data: nil, metadata: { correlation_id: "cor", causation_id: "cau" })
    expect(event.event_id).to eq("mem")
    expect(event.correlation_id).to eq("cor")
    expect(event.causation_id).to eq("cau")
  end

  specify "chainable" do
    e0 = factory.call(event_id: "doh")
    e1 = factory.call(event_id: "yay")
    chained = e1.correlate_with(e0)

    expect(chained).to eq(e1)
  end

  specify "correlate_with a command" do
    command = Struct.new(:correlation_id, :message_id).new("correlation", "command_id")
    event = factory.call(event_id: "event")
    event.correlate_with(command)
    expect(event.event_id).to eq("event")
    expect(event.correlation_id).to eq("correlation")
    expect(event.causation_id).to eq("command_id")

    command = Struct.new(:correlation_id, :message_id).new(nil, "command_id")
    event = factory.call(event_id: "event")
    event.correlate_with(command)
    expect(event.event_id).to eq("event")
    expect(event.correlation_id).to eq("command_id")
    expect(event.causation_id).to eq("command_id")
  end
end
