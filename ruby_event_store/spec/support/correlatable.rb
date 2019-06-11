RSpec.shared_examples :correlatable do |klass|
  specify "correlation_id && causation_id" do
    e0 = klass.new(event_id: "doh", data: nil)
    expect(e0.event_id).to       eq("doh")
    expect(e0.correlation_id).to eq(nil)
    expect(e0.causation_id).to   eq(nil)

    e1 = klass.new(event_id: "yay", data: nil)
    e1.correlate_with(e0)
    expect(e1.event_id).to       eq("yay")
    expect(e1.correlation_id).to eq("doh")
    expect(e1.causation_id).to   eq("doh")

    e2 = klass.new(event_id: "jeb", data: nil)
    e2.correlate_with(e1)
    expect(e2.event_id).to       eq("jeb")
    expect(e2.correlation_id).to eq("doh")
    expect(e2.causation_id).to   eq("yay")

    event = klass.new(
      event_id: "mem",
      data: nil,
      metadata: {
        correlation_id: "cor",
        causation_id: "cau"
    })
    expect(event.event_id).to       eq("mem")
    expect(event.correlation_id).to eq("cor")
    expect(event.causation_id).to   eq("cau")
  end

  specify "chainable" do
    e0 = klass.new(event_id: "doh", data: nil)
    e1 = klass.new(event_id: "yay", data: nil)
    chained = e1.correlate_with(e0)
    
    expect(chained).to eq(e1)
  end

  specify "correlate_with a command" do
    command = Struct.new(:correlation_id, :message_id).new("correlation", "command_id")
    event = klass.new(event_id: "event", data: nil)
    event.correlate_with(command)
    expect(event.event_id).to       eq("event")
    expect(event.correlation_id).to eq("correlation")
    expect(event.causation_id).to   eq("command_id")

    command = Struct.new(:correlation_id, :message_id).new(nil, "command_id")
    event = klass.new(event_id: "event", data: nil)
    event.correlate_with(command)
    expect(event.event_id).to       eq("event")
    expect(event.correlation_id).to eq("command_id")
    expect(event.causation_id).to   eq("command_id")
  end
end