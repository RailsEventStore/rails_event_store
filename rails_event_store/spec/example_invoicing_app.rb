
class OrderCreated
  def initialize(customer_name)
    @customer_name = customer_name
  end

  def data
    {
        data: {
            customer_name: @customer_name,
        },
        event_type: "OrderCreated"
    }
  end
end

class ProductAdded
  def initialize(product_name, quantity, price)
    @product_name = product_name
    @quantity     = quantity
    @price        = price
  end

  def data
    {
        data: {
            product_name: @product_name,
            quantity:     @quantity,
            price:        @price
        },
        event_type: "ProductAdded"
    }
  end
end

class PriceChanged
  def initialize(product_name, new_price)
    @product_name = product_name
    @new_price    = new_price
  end

  def data
    {
        data: {
            product_name: @product_name,
            new_price:    @new_price
        },
        event_type: "PriceChanged"
    }
  end
end

class InvoiceReadModel
  def initialize(events=[])
    @items = []
    events.each{|event| handle_event(event)}
  end

  def items
    @items
  end

  def total_amount
    @items.map(&:value).inject(0, :+).to_s
  end

  def handle_event(event)
    if event.event_type == "ProductAdded"
      add_new_invoice_item(event.data[:product_name])
      set_price(event.data[:product_name], event.data[:price])
      set_quantity(event.data[:product_name], event.data[:quantity])
    end

    if event.event_type == "PriceChanged"
      set_price(event.data[:product_name], event.data[:new_price])
    end
  end

  private


  def add_new_invoice_item(product_name)
    @items << InvoiceItem.new(product_name)
  end

  def set_price(product_name, new_price)
    find_item_by(product_name).change_price(new_price)
  end

  def set_quantity(product_name, new_quantity)
    find_item_by(product_name).change_quantity(new_quantity)
  end

  def find_item_by(product_name)
    @items.detect { |item| item.product_name == product_name }
  end


  class InvoiceItem
    attr_reader :product_name

    def initialize(product_name)
      @product_name = product_name
    end

    def change_price(new_price)
      @price = new_price
    end

    def change_quantity(new_quantity)
      @quantity = new_quantity
    end

    def value
      (@price * @quantity)
    end

    def formatted_value
      value.to_s
    end

  end


end
