# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/deprecations"

RSpec.describe RubyEventStore::Deprecations do
  after { described_class.reset! }

  it "emits registered warning to stderr" do
    described_class.register(:foo, "foo is deprecated")
    expect { described_class.warn(:foo) }.to output(/foo is deprecated/).to_stderr
  end

  it "suppresses warning when told to" do
    described_class.register(:foo, "foo is deprecated")
    described_class.suppress(:foo)
    expect { described_class.warn(:foo) }.not_to output.to_stderr
  end
end
