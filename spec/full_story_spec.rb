require 'spec_helper'

module RailsEventStore
  describe Client do

    specify 'restoring a read model from all events' do
      client = Client.new(EventInMemoryRepository.new)
      publish_ordering_events(client)
      order_events = client.read_all_events('order_1')
      invoice = InvoiceReadModel.new(order_events)
      assert_invoice_structure(invoice)
    end

    specify 'building a read model runtime - pub_sub' do
      client = Client.new(EventInMemoryRepository.new)
      invoice = InvoiceReadModel.new
      client.subscribe(invoice, ['PriceChanged', 'ProductAdded'])
      publish_ordering_events(client)
      assert_invoice_structure(invoice)
    end

    private

    def publish_ordering_events(client)
      ordering_events.each { |event| client.publish_event(event, 'order_1') }
    end

    def ordering_events
      [
          OrderCreated.new(customer_name: 'andrzejkrzywda'),
          ProductAdded.new(product_name: 'Rails meets ReactJS', quantity: 1, price: 49),
          ProductAdded.new(product_name: 'Fearless Refactoring', quantity: 1, price: 49),
          PriceChanged.new(product_name: 'Rails meets ReactJS', new_price: 24)
      ]
    end

    def assert_invoice_structure(invoice)
      assert_invoice(
          [
              ['Rails meets ReactJS', 1, '24', '24'],
              ['Fearless Refactoring', 1, '49', '49']
          ],
          '73',
          invoice
      )
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

