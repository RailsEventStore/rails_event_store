require "rails_helper"

RSpec.describe DresRails::Queue do
  specify ".last_processed_event_id_for" do
    DresRails::Queue.delete_all
    expect(DresRails::Queue.last_processed_event_id_for("app")).to be_nil

    DresRails::Queue.create!(name: "app", last_processed_event_id: nil)
    expect(DresRails::Queue.last_processed_event_id_for("app")).to be_nil

    DresRails::Queue.last.update_attributes!(last_processed_event_id: "b1bd0a0e-6ae5-4895-8788-336972d3ecdb")
    expect(DresRails::Queue.last_processed_event_id_for("app")).to eq("b1bd0a0e-6ae5-4895-8788-336972d3ecdb")
  end

end