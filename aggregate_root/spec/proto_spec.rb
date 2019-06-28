# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/helpers/protobuf_helper'

RSpec.describe 'proto compatibility' do
  include ProtobufHelper
  extend  ProtobufHelper

  require_protobuf_dependencies do
    Google::Protobuf::DescriptorPool.generated_pool.build do
      add_message "res_testing.SpanishInquisition" do
      end
    end

    Google::Protobuf::DescriptorPool.generated_pool.build do
      add_message "res_testing.OrderPaid" do
      end
    end

    module ResTesting
      SpanishInquisition = Google::Protobuf::DescriptorPool.generated_pool.lookup("res_testing.SpanishInquisition").msgclass
      OrderPaid          = Google::Protobuf::DescriptorPool.generated_pool.lookup("res_testing.OrderPaid").msgclass

      class Order
        include AggregateRoot

        def initialize(uuid)
          @status = :draft
          @uuid   = uuid
        end

        attr_accessor :status

        private

        def apply_order_created(*)
          @status = :created
        end

        on 'res_testing.OrderPaid' do |_event|
          @status = :paid
        end
      end
    end
  end

  before(:each) { require_protobuf_dependencies }

  it "should receive a method call based on a default apply strategy" do
    order = ResTesting::Order.new(SecureRandom.uuid)
    order_created =
      RubyEventStore::Proto.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data:     ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id:    "K3THNX9",
        )
      )

    order.apply(order_created)
    expect(order.status).to eq :created
  end

  it "should receive a method call based on a default apply strategy via on handler" do
    order = ResTesting::Order.new(SecureRandom.uuid)
    order_paid =
      RubyEventStore::Proto.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data:     ResTesting::OrderPaid.new
      )

    order.apply(order_paid)
    expect(order.status).to eq :paid
  end

  it "should raise error for missing apply method based on a default apply strategy" do
    order = ResTesting::Order.new(SecureRandom.uuid)
    spanish_inquisition =
      RubyEventStore::Proto.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data:     ResTesting::SpanishInquisition.new
      )

    expect { order.apply(spanish_inquisition) }.to raise_error(AggregateRoot::MissingHandler, "Missing handler method apply_spanish_inquisition on aggregate ResTesting::Order")
  end
end
