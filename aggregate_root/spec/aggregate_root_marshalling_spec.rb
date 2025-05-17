# frozen_string_literal: true

require "spec_helper"

::RSpec.describe AggregateRoot do
  let(:uuid) { SecureRandom.uuid }
  let(:order_klass) do
    Class.new do
      def initialize(uuid)
        @uuid = uuid
      end
      attr_accessor :uuid
      include AggregateRoot
    end
  end

  specify "#marshal_dump" do
    order = order_klass.new(uuid)
    expect(order.marshal_dump).to eq({ :@uuid => uuid })
  end

  specify "#marshal_load" do
    order = order_klass.new(uuid)
    order.marshal_load({ :@uuid => uuid, :@version => 10, :@unpublished_events => [Orders::Events::OrderCreated.new] })
    expect(order.uuid).to eq(uuid)
    expect(order.version).to eq(-1)
    expect(order.unpublished_events.to_a).to be_empty
  end
end
