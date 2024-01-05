# frozen_string_literal: true

require "rails_helper"
require_relative "../../db/migrate/20180802140810_create_dres_rails_queues"
require_relative "../../db/migrate/20180809123523_create_queue_jobs_table"

::RSpec.describe DresRails::Queue do
  around do |example|
    begin
      CreateDresRailsQueues.new.change
      CreateQueueJobsTable.new.change
      example.call
    ensure
      ActiveRecord::Migration.new.drop_table "dres_rails_queues"
      ActiveRecord::Migration.new.drop_table "dres_rails_queue_jobs"
    end
  end

  specify ".last_processed_event_id_for" do
    expect(DresRails::Queue.last_processed_event_id_for("app")).to be_nil

    DresRails::Queue.create!(name: "app", last_processed_event_id: nil)
    expect(DresRails::Queue.last_processed_event_id_for("app")).to be_nil

    DresRails::Queue.last.update!(last_processed_event_id: "b1bd0a0e-6ae5-4895-8788-336972d3ecdb")
    expect(DresRails::Queue.last_processed_event_id_for("app")).to eq("b1bd0a0e-6ae5-4895-8788-336972d3ecdb")
  end

  specify "process successfuly once" do
    q = DresRails::Queue.create!(name: "app", last_processed_event_id: nil)

    processed = 0
    q.process(event_id = "ffdd79ea-a6c6-4cdc-9802-a8d7525a9072") { processed += 1 }

    expect(q.jobs.where(event_id: event_id).map(&:state)).to eq(["success"])
    expect(q.last_processed_event_id).to eq(event_id)
    expect(processed).to eq(1)

    q.process(event_id) { processed += 1 }
    expect(processed).to eq(1)
    expect(q.jobs.where(event_id: event_id).map(&:state)).to eq(["success"])
  end

  specify "failure can be processed multiple times" do
    q = DresRails::Queue.create!(name: "app", last_processed_event_id: nil)
    event_id = "4db3e653-68c7-4c5b-b342-459417d1aaba"
    processed = 0

    expect do
      q.process(event_id) do
        processed += 1
        raise StandardError
      end
    end.to raise_error(StandardError)

    expect(q.jobs.where(event_id: event_id).map(&:state)).to eq(["failure"])
    expect(q.last_processed_event_id).to eq(event_id)
    expect(processed).to eq(1)

    q.process(event_id) { processed += 1 }

    expect(q.jobs.where(event_id: event_id).map(&:state)).to eq(%w[failure success])
    expect(q.last_processed_event_id).to eq(event_id)
    expect(processed).to eq(2)
  end
end
