# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyEventStore::Deprecations do

  it "emits registered warning to stderr" do
    described_class.register(:foo, "foo is deprecated")
    expect { described_class.warn(:foo) }.to output(/foo is deprecated/).to_stderr
  end

  it "suppresses warning when told to" do
    described_class.register(:foo, "foo is deprecated")
    described_class.suppress(:foo)
    expect { described_class.warn(:foo) }.not_to output.to_stderr
  end

  it "emits warning only once even if called multiple times" do
    described_class.register(:foo, "foo is deprecated")
    expect { 3.times { described_class.warn(:foo) } }
      .to output("[DEPRECATION] foo is deprecated\n").to_stderr
  end

  it "emits message keyword argument instead of registered message" do
    described_class.register(:foo, "foo registered message")
    expect { described_class.warn(:foo, message: "custom override message") }
      .to output(/custom override message/).to_stderr
  end

  it "reset! clears suppressions so previously suppressed warning can fire again" do
    described_class.register(:foo, "foo is deprecated")
    described_class.suppress(:foo)
    described_class.reset!
    expect { described_class.warn(:foo) }.to output(/foo is deprecated/).to_stderr
  end
end
