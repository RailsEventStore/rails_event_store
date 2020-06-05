# frozen_string_literal: true

require_relative 'payments/application_record'
require_relative '../../lib/event'

module Payments
  def self.setup(config)
    @@public_event_store = config.event_store
    @@module_event_store = RailsEventStore::Client.new(
      repository: RailsEventStoreActiveRecord::EventRepository.new(
        Payments::ApplicationRecord),
      mapper: RubyEventStore::Mappers::Default.new(
        serializer: JSON, events_class_remapping: events_class_remapping)
    )

    # Subscribe public event handlers below
    config.event_store.tap do |store|
#      store.subscribe(Authorize.new, to: [Initiated])
    end

    # Register commands handled by this module below
    # config.command_bus.tap do |bus|
    #   bus.register(SubmitPayment, Payments::OnSubmit.new)
    # end
  end

  def self.public_event_store
    @@public_event_store
  end

  def self.event_store
    @@module_event_store
  end

  def self.events_class_remapping
    {
      'order-submitted'               => Initiated,
      'payment-authorized'            => Authorized,
      'payment-authorization-failed'  => AuthorizationFailed,
    }
  end

  class Initiated < Event
    event_type 'order-submitted'
    attribute  :customer_id, Types::Strict::String
    attribute  :order_id, Types::Strict::String
    attribute  :total_amount, Types::Strict::Float
  end

  class Authorized < Event
    event_type 'payment-authorized'
    attribute  :transaction_id, Types::Strict::Integer
    attribute  :order_id, Types::Strict::String
  end

  class AuthorizationFailed < Event
    event_type 'payment-authorization-failed'
    attribute  :transaction_id, Types::Strict::Integer
    attribute  :order_id, Types::Strict::String
  end
end
