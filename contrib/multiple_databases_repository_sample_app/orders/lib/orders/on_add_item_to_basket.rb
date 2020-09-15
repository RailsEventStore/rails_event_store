module Orders
  class OnAddItemToBasket
    include CommandHandler

    def call(command)
      with_aggregate(Order.new(command.order_id), command.order_id) do |order|
        order.add_item(command.product_id)
      end
    end
  end
end
