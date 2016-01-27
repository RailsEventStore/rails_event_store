RSpec::Matchers.define :be_event do |expected|
  match do |actual|
    expect(actual.event_type).to eq expected[:event_type]
    expect(actual.data).to eq expected[:data]
    expect(actual.metadata).to eq expected[:metadata] if expected.key?(:metadata)
    expect(actual.event_id).to eq expected[:event_id] if expected.key?(:event_id)
    true
  end
end
