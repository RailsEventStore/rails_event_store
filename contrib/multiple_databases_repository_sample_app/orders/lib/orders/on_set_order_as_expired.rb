module Orders
  class OnSetOrderAsExpired
    include CommandHandler

    def call(command)
      with_aggregate(Order.new(command.order_id), command.order_id) do |order|
        order.expire
      end
    end
  end
end
