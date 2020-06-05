# frozen_string_literal: true

require_relative 'orders/application_record'
require_relative '../../lib/event'

module Orders
  def self.setup(config)
    @@public_event_store = config.event_store
    @@module_event_store = RailsEventStore::Client.new(
      repository: RailsEventStoreActiveRecord::EventRepository.new(
        Orders::ApplicationRecord),
      mapper: RubyEventStore::Mappers::Default.new(
        serializer: JSON, events_class_remapping: events_class_remapping)
    )

    # Subscribe public event handlers below
    config.event_store.tap do |store|
#      store.subscribe(MarkAsPaid.new, to: [Paid])
#      store.subscribe(RequestPayment.new, to: [PaymentFailed])
    end

    # Register commands handled by this module below
    config.command_bus.tap do |bus|
#      bus.register(SubmitOrder, Submit.new)
    end
  end

  def self.public_event_store
    @@public_event_store
  end

  def self.event_store
    @@module_event_store
  end

  def self.events_class_remapping
    {
      'order-submitted'               => Submitted,
    }
  end

  class Paid < Event
    event_type 'payment-completed'
    attribute  :order_id, Types::Strict::String
  end
  class PaymentFailed < Event
    event_type 'payment-failed'
    attribute  :order_id, Types::Strict::String
  end
  class Submitted < Event
    event_type 'order-submitted'
    attribute  :order_id, Types::Strict::String
    attribute  :customer_id, Types::Strict::String
    attribute  :total_amount, Types::Strict::Float
  end
end
