class OrderCreated < RailsEventStore::Event
  attr_accessor :customer_name
end

class ProductAdded < RailsEventStore::Event
  attr_accessor :product_name, :quantity, :price
end

class PriceChanged < RailsEventStore::Event
  attr_accessor :product_name, :new_price
end

class InvoiceReadModel
  def initialize(events=[])
    @items = []
    events.each { |event| handle_event(event) }
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
