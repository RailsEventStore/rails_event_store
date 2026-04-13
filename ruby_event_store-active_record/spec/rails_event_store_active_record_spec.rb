# frozen_string_literal: true

require "spec_helper"

::RSpec.describe "rails_event_store_active_record deprecation" do
  specify "warns when loaded" do
    expect {
      load File.expand_path("../lib/rails_event_store_active_record.rb", __dir__)
    }.to output(
      /The 'rails_event_store_active_record' gem has been renamed and is deprecated\./
    ).to_stderr
  end
end
