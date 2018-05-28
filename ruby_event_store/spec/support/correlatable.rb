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
end