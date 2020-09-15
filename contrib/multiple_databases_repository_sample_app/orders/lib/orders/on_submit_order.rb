module Orders
  class OnSubmitOrder
    include CommandHandler

    def initialize(event_store, number_generator_factory:)
      @repository = AggregateRoot::InstrumentedRepository.new(
        AggregateRoot::Repository.new(event_store),
        ActiveSupport::Notifications
      )
      @number_generator = number_generator_factory.call
    end

    def call(command)
      with_aggregate(Order.new(command.order_id), command.order_id) do |order|
        order_number = number_generator.call
        order.submit(
          order_number,
          command.customer_id,
          command.delivery_address_id,
          command.payment_method_id
        )
      end
    end

    private

    attr_accessor :number_generator
  end
end
