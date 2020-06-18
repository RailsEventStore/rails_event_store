require 'aggregate_root'

module Orders
  class Order
    include AggregateRoot

    AlreadySubmitted = Class.new(StandardError)
    NotSubmitted = Class.new(StandardError)
    MissingCustomer = Class.new(StandardError)

    def initialize(id)
      @id = id
      @state = :draft
      @order_lines = []
    end

    def submit(order_number, customer_id, delivery_address_id, payment_method_id)
      raise AlreadySubmitted if @state == :submitted
      raise MissingCustomer unless customer_id
      apply OrderSubmitted.new(data: {
        order_id: @id,
        order_number: order_number,
        customer_id: customer_id,
        delivery_address_id: delivery_address_id,
        payment_method_id: payment_method_id,
      })
    end

    def add_item(product_id)
      raise AlreadySubmitted unless @state == :draft
      apply ItemAddedToBasket.new(data: {order_id: @id, product_id: product_id})
    end

    def remove_item(product_id)
      raise AlreadySubmitted unless @state == :draft
      apply ItemRemovedFromBasket.new(data: {order_id: @id, product_id: product_id})
    end

    on OrderSubmitted do |event|
      @customer_id = event.data[:customer_id]
      @number = event.data[:order_number]
      @state = :submitted
    end

    on ItemAddedToBasket do |event|
      product_id = event.data[:product_id]
      order_line = find_order_line(product_id)
      unless order_line
        order_line = create_order_line(product_id)
        @order_lines << order_line
      end
      order_line.increase_quantity
    end

    on ItemRemovedFromBasket do |event|
      product_id = event.data[:product_id]
      order_line = find_order_line(product_id)
      return unless order_line
      order_line.decrease_quantity
      remove_order_line(order_line) if order_line.empty?
    end

    private

    def find_order_line(product_id)
      @order_lines.select { |line| line.product_id == product_id }.first
    end

    def create_order_line(product_id)
      OrderLine.new(product_id)
    end

    def remove_order_line(order_line)
      @order_lines.delete(order_line)
    end
  end
end
