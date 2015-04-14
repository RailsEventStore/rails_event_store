require 'spec_helper'
require 'example_invoicing_app'

module RailsEventStore

  describe "Event Store" do

    specify "happy path" do
      client = Client.new(EventInMemoryRepository.new)
      events = [
          OrderCreated.new("andrzejkrzywda"),
          ProductAdded.new("Rails meets ReactJS",  1, 49),
          ProductAdded.new("Fearless Refactoring", 1, 49),
          PriceChanged.new("Rails meets ReactJS",  24)
      ]
      events.each{ |event| client.append_to_stream("order_1", event.data) }


      invoice = InvoiceReadModel.new(order_events(client, "order_1"))
      assert_invoice(
          [
              ["Rails meets ReactJS" , 1, "24", "24"],
              ["Fearless Refactoring", 1, "49", "49"]
          ],
          "73",
          invoice
      )
    end

    def order_events(client, stream_name)
      client.read_all_events_forward(stream_name)
    end

    private

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

