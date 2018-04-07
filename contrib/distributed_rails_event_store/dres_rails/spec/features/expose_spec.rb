require "rails_helper"
require "capybara"
require "timecop"
require "ruby_event_store"

RSpec.describe "DresRails::ApplicationController" do
  include SchemaHelper
  around(:all) do |example|
    begin
      load_database_schema
      example.run
    ensure
      drop_database
    end
  end

  before(:each) do
    ActiveRecord::Base.connection.execute("TRUNCATE event_store_events")
    ActiveRecord::Base.connection.execute("TRUNCATE event_store_events_in_streams")
  end

  let(:repository) do
    DistributedRepository.new
  end
  let(:res) do
    RubyEventStore::Client.new(repository: repository)
  end

  class MyEvent < RubyEventStore::Event
  end

  around(:each) do |spec|
    Timecop.freeze(Time.utc(2018, 4, 7, 12, 30)) do
      spec.call
    end
  end

  specify "returns JSON with serialized events" do
    res.publish_events([
      MyEvent.new(
        data: {one: 1},
        event_id: "dfc7f58d-aae3-4d21-8f3a-957bfa765ef8",
      ),
      MyEvent.new(
        data: {two: 2},
        event_id:"b2f58e9c-0887-4fbf-99a8-0bb19cfebeef",
      ),
    ])
    visit "/dres_rails"
    expect(JSON.parse(page.body)).to eq({
      "events"=>[{
        "event_id"=>"dfc7f58d-aae3-4d21-8f3a-957bfa765ef8",
        "data"=>"---\n:one: 1\n",
        "metadata"=>"---\n:timestamp: 2018-04-07 12:30:00.000000000 Z\n",
        "event_type"=>"MyEvent"
      }, {
        "event_id"=>"b2f58e9c-0887-4fbf-99a8-0bb19cfebeef",
        "data"=>"---\n:two: 2\n",
        "metadata"=>"---\n:timestamp: 2018-04-07 12:30:00.000000000 Z\n",
        "event_type"=>"MyEvent"
    }]})
    expect(page.body).to eq(File.read("../shared_spec/body1.json"))
  end
end