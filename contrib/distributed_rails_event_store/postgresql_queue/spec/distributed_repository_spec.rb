require 'spec_helper'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'
require 'rails_event_store_active_record/event'
# require_relative '../../rails_event_store/ruby_event_store/spec/mappers/events_pb.rb'

RSpec.describe DistributedRepository do
  include SchemaHelper

  around(:each) do |example|
    begin
      establish_database_connection
      load_database_schema
      example.run
    ensure
      drop_database
    end
  end

  let(:test_race_conditions_auto)  { true }
  let(:test_race_conditions_any)   { true }
  let(:test_expected_version_auto) { true }
  let(:test_link_events_to_stream) { true }

  it_behaves_like :event_repository, DistributedRepository

  def cleanup_concurrency_test
    ActiveRecord::Base.connection_pool.disconnect!
  end

  def verify_conncurency_assumptions
    expect(ActiveRecord::Base.connection.pool.size).to eq(5)
  end

  def additional_limited_concurrency_for_auto_check
    positions = RailsEventStoreActiveRecord::EventInStream.
      where(stream: "stream").
      order("position ASC").
      map(&:position)
    expect(positions).to eq((0..positions.size-1).to_a)
  end
end