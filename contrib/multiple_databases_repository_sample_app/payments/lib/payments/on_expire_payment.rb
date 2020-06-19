module Payments
  class OnExpirePayment
    include CommandHandler

    def call(command)
      with_aggregate(Payment.new, command.transaction_id) do |payment|
        payment.expire
      end
    end
  end
end
