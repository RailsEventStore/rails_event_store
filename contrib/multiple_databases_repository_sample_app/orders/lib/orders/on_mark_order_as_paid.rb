module Orders
  class OnMarkOrderAsPaid
    include CommandHandler

    def call(command)
      with_aggregate(Order.new(command.order_id), command.order_id) do |order|
        order.mark_as_paid(command.transaction_id)
      end
    end
  end
end
