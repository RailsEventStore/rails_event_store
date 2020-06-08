module Payments
  class OnAuthorizePayment
    include CommandHandler

    def call(command)
      with_aggregate(Payment.new, command.transaction_id) do |payment|
        payment.authorize(command.transaction_id, command.order_id)
      end
    end
  end
end
