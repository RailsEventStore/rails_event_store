RSpec.shared_examples :event do |event_class, data, metadata|
  it 'allows initialization' do
    expect {
      event_class.new(event_id: Object.new, data: data || Object.new, metadata: metadata || {})
    }.not_to raise_error
  end

  it 'provides event_id as string' do
    event = event_class.new
    expect(event.event_id).to be_an_instance_of(String)
    expect(event.event_id).not_to eq ''
    expect(event.event_id).not_to eq nil
  end

  it 'provides message_id as string' do
    event = event_class.new
    expect(event.message_id).to be_an_instance_of(String)
  end

  it 'message_id is the same as event_id' do
    event = event_class.new
    expect(event.event_id).to eq event.message_id
  end

  it 'exposes given event_id to string' do
    event = event_class.new(event_id: 1234567890)
    expect(event.event_id).to eq '1234567890'
  end

  it 'provides event type as string' do
    event = event_class.new
    expect(event.event_type).to be_an_instance_of(String)
    expect(event.event_type).not_to eq ''
    expect(event.event_type).not_to eq nil
  end

  it "provides data" do
    event = event_class.new
    expect(event).to respond_to(:data).with(0).arguments
  end

  it "metadata allows to read keys" do
    event = event_class.new
    expect(event.metadata).to respond_to(:[]).with(1).arguments
  end

  it "metadata allows to set keys value" do
    event = event_class.new
    expect(event.metadata).to respond_to(:[]=).with(2).argument
  end

  it "metadata allows to fetch keys" do
    event = event_class.new
    expect(event.metadata).to respond_to(:fetch).with(1).argument
  end

  it "metadata allows to check existence of keys" do
    event = event_class.new
    expect(event.metadata).to respond_to(:has_key?).with(1).argument
  end

  it "metadata allows to iterate through keys" do
    event = event_class.new
    expect(event.metadata).to respond_to(:each_with_object).with(1).argument
  end

  it "metadata must convert to hash" do
    event = event_class.new
    expect(event.metadata).to respond_to(:to_h).with(0).argument
  end
end
