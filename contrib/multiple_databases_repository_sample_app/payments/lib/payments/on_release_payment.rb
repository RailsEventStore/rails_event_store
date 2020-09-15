module Payments
  class OnReleasePayment
    include CommandHandler

    def call(command)
      with_aggregate(Payment.new, command.transaction_id) do |payment|
        payment.release
      end
    end
  end
end
