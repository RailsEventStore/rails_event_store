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
    RailsEventStoreActiveRecord::PgLinearizedEventRepository.new
  end
  let(:res) do
    RailsEventStore::Client.new(repository: repository)
  end

  class MyEvent < RubyEventStore::Event
  end

  around(:each) do |spec|
    Timecop.freeze(Time.utc(2018, 4, 7, 12, 30)) do
      spec.call
    end
  end

  before do
    Rails.configuration.event_store = res
  end

  specify "Auth" do
    page.driver.header 'RES-Api-Key', "Wrong"
    expect do
      visit "/dres_rails"
    end.to raise_error(ActionController::RoutingError)

    page.driver.header 'RES-Api-Key', "33bbd0ea-b7ce-49d5-bc9d-198f7884c485"
    expect do
      visit "/dres_rails"
    end.not_to raise_error
  end

  specify "returns JSON with serialized events" do
    res.publish([
      MyEvent.new(
        data: {one: 1},
        event_id: "dfc7f58d-aae3-4d21-8f3a-957bfa765ef8",
      ),
      MyEvent.new(
        data: {two: 2},
        event_id:"b2f58e9c-0887-4fbf-99a8-0bb19cfebeef",
      ),
    ])

    page.driver.header 'RES-Api-Key', "33bbd0ea-b7ce-49d5-bc9d-198f7884c485"
    visit "/dres_rails"
    expect(JSON.parse(page.body)).to eq({
      "after" => "head",
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