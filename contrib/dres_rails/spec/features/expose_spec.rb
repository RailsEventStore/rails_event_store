# frozen_string_literal: true

require "rails_helper"
require "capybara"
require "timecop"
require "ruby_event_store"

::RSpec.describe "DresRails::ApplicationController" do
  include SchemaHelper
  around do |example|
    begin
      load_database_schema
      example.run
    ensure
      drop_database
    end
  end

  before do
    ::ActiveRecord::Base.connection.execute("TRUNCATE event_store_events_in_streams")
    ::ActiveRecord::Base.connection.execute("DELETE FROM event_store_events")
  end

  let(:repository) { RubyEventStore::ActiveRecord::PgLinearizedEventRepository.new(serializer: YAML) }
  let(:res) do
    RailsEventStore::Client.new(
      repository: repository,
      correlation_id_generator: -> { "15b861b5-5697-40ae-bfea-7f01329c3385" },
    )
  end

  class MyEvent < RubyEventStore::Event
  end

  around { |spec| Timecop.freeze(Time.utc(2018, 4, 7, 12, 30)) { spec.call } }

  before { Rails.configuration.event_store = res }

  specify "Auth" do
    page.driver.header "RES-Api-Key", "Wrong"
    visit "/dres_rails"
    expect(page.status_code).to eq(404)

    page.driver.header "RES-Api-Key", "33bbd0ea-b7ce-49d5-bc9d-198f7884c485"
    visit "/dres_rails"
    expect(page.status_code).to eq(200)
  end

  specify "returns JSON with serialized events" do
    res.publish(
      [
        MyEvent.new(data: { one: 1 }, event_id: "dfc7f58d-aae3-4d21-8f3a-957bfa765ef8"),
        MyEvent.new(data: { two: 2 }, event_id: "b2f58e9c-0887-4fbf-99a8-0bb19cfebeef"),
      ],
    )

    page.driver.header "RES-Api-Key", "33bbd0ea-b7ce-49d5-bc9d-198f7884c485"
    visit "/dres_rails"
    expect(JSON.parse(page.body)).to eq(
      {
        "after" => "head",
        "events" => [
          {
            "event_id" => "dfc7f58d-aae3-4d21-8f3a-957bfa765ef8",
            "data" => "---\n:one: 1\n",
            "metadata" => "---\n:correlation_id: 15b861b5-5697-40ae-bfea-7f01329c3385\n",
            "valid_at" => "2018-04-07T12:30:00.000Z",
            "timestamp" => "2018-04-07T12:30:00.000Z",
            "event_type" => "MyEvent",
          },
          {
            "event_id" => "b2f58e9c-0887-4fbf-99a8-0bb19cfebeef",
            "data" => "---\n:two: 2\n",
            "metadata" => "---\n:correlation_id: 15b861b5-5697-40ae-bfea-7f01329c3385\n",
            "valid_at" => "2018-04-07T12:30:00.000Z",
            "timestamp" => "2018-04-07T12:30:00.000Z",
            "event_type" => "MyEvent",
          },
        ],
      },
    )
  end
end
