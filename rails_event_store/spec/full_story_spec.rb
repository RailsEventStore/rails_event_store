# frozen_string_literal: true

require "spec_helper"

module RailsEventStore
  ::RSpec.describe Client do
    specify "restoring a read model from all events" do
      client = Client.new
      publish_ordering_events(client)
      order_events = client.read.stream("order_1").to_a
      invoice = InvoiceReadModel.new(order_events)
      assert_invoice_structure(invoice)
    end

    specify "building a read model runtime - pub_sub" do
      client = Client.new
      invoice = InvoiceReadModel.new
      client.subscribe(invoice, to: [PriceChanged, ProductAdded])
      publish_ordering_events(client)
      assert_invoice_structure(invoice)
    end

    specify "building a read model based on all events" do
      client = Client.new
      invoice = InvoiceReadModel.new
      client.subscribe_to_all_events(invoice)
      publish_ordering_events(client)
      assert_invoice_structure(invoice)
    end

    private

    def publish_ordering_events(client)
      ordering_events.each { |event| client.publish(event, stream_name: "order_1") }
    end

    def ordering_events
      [
        OrderCreated.new(data: { customer_name: "andrzejkrzywda" }),
        ProductAdded.new(data: { product_name: "Rails meets ReactJS", quantity: 1, price: 49 }),
        ProductAdded.new(data: { product_name: "Fearless Refactoring", quantity: 1, price: 49 }),
        PriceChanged.new(data: { product_name: "Rails meets ReactJS", new_price: 24 }),
      ]
    end

    def assert_invoice_structure(invoice)
      assert_invoice([["Rails meets ReactJS", 1, "24", "24"], ["Fearless Refactoring", 1, "49", "49"]], "73", invoice)
    end

    def assert_invoice(expected_items, expected_total, invoice)
      assert_total_value(expected_total, invoice)
      assert_items_length(expected_items, invoice)
      assert_invoice_items_content(expected_items, invoice)
    end

    def assert_total_value(expected_total, invoice)
      expect(invoice.total_amount).to(eql(expected_total))
    end

    def assert_invoice_items_content(expected_items, invoice)
      expected_items.each_with_index do |item, i|
        expect(invoice.items[i].product_name).to(eql(item[0]))
        expect(invoice.items[i].formatted_value).to(eql(item[3]))
      end
    end

    def assert_items_length(expected_items, invoice)
      expect(expected_items.length).to(eql(invoice.items.length))
    end
  end
end
