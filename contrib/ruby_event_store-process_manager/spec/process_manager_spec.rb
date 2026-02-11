# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyEventStore::ProcessManager do
  class TestProcess
    include RubyEventStore::ProcessManager
  end

  specify "can be included in a class" do
    expect(TestProcess.ancestors).to include(RubyEventStore::ProcessManager)
  end
end
