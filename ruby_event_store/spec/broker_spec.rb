# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/broker_lint"

module RubyEventStore
  ::RSpec.describe Broker do
    it_behaves_like "broker", Broker

    specify "#cleaner_inspect" do
      broker = Broker.new

      expect(broker.cleaner_inspect).to eq(<<~EOS.chomp)
        #<RubyEventStore::Broker:0x#{broker.object_id.to_s(16)}>
          - dispatcher: #{broker.instance_variable_get(:@dispatcher).inspect}
      EOS
    end

    specify "#cleaner_inspect with indent" do
      broker = Broker.new

      expect(broker.cleaner_inspect(indent: 4)).to eq(<<~EOS.chomp)
        #{' ' * 4}#<RubyEventStore::Broker:0x#{broker.object_id.to_s(16)}>
        #{' ' * 4}  - dispatcher: #{broker.instance_variable_get(:@dispatcher).inspect}
      EOS
    end
  end
end
