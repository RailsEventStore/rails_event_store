# frozen_string_literal: true

# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: events.proto3

require "google/protobuf"

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "res_testing.OrderCreated" do
    optional :order_id, :string, 1
    optional :customer_id, :int32, 2
  end
end

module ResTesting
  OrderCreated = Google::Protobuf::DescriptorPool.generated_pool.lookup("res_testing.OrderCreated").msgclass
end
