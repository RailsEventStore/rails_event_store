RSpec::Matchers.define :be_event do |expected|
  match do |actual|
    expect(actual.event_type).to eq expected[:event_type]
    expect(actual.data).to eq expected[:data]
    if expected.key? :event_id then expect(actual.event_id).to eq expected[:event_id] else true end
  end
end
