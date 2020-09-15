module Orders
  class OrderLine
    include Comparable
    attr_reader :product_id

    def initialize(product_id)
      @product_id = product_id
      @quantity = 0
    end

    def increase_quantity
      @quantity += 1
    end

    def decrease_quantity
      @quantity -= 1
    end

    def empty?
      @quantity == 0
    end

    def <=>(other)
      self.product_id <=> other.product_id
    end

    private

    attr_accessor :quantity
  end
end
