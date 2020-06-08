module Payments
  class OnCapturePayment
    include CommandHandler

    def call(command)
      with_aggregate(Payment.new, command.transaction_id) do |payment|
        payment.capture
      end
    end
  end
end
