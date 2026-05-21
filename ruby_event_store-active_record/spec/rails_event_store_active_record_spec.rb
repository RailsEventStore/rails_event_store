# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/deprecations"

RSpec.describe "rails_event_store_active_record deprecation" do
  after { RubyEventStore::Deprecations.reset! }

  it "warns when loaded directly" do
    expect { load File.expand_path("../lib/rails_event_store_active_record.rb", __dir__) }.to output(
      /ruby_event_store-active_record/,
    ).to_stderr
  end

  it "does not warn when suppressed (simulating rails_event_store load)" do
    RubyEventStore::Deprecations.suppress(:rails_event_store_active_record_renamed)
    expect { load File.expand_path("../lib/rails_event_store_active_record.rb", __dir__) }.not_to output.to_stderr
  end
end
