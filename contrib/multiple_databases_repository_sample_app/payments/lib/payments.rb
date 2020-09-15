# frozen_string_literal: true

require_relative 'payments/application_record'
require_relative '../../lib/event'
require_relative '../../lib/types'
require_relative '../../lib/command'
require_relative '../../lib/command_handler'

require_dependency 'payments/payment_authorized'
require_dependency 'payments/payment_captured'
require_dependency 'payments/payment_released'
require_dependency 'payments/payment_expired'

require_dependency 'payments/authorize_payment'
require_dependency 'payments/capture_payment'
require_dependency 'payments/release_payment'
require_dependency 'payments/set_payment_as_expired'
require_dependency 'payments/complete_payment'

require_dependency 'payments/on_authorize_payment'
require_dependency 'payments/on_capture_payment'
require_dependency 'payments/on_release_payment'
require_dependency 'payments/on_expire_payment'
require_dependency 'payments/on_complete_payment'

require_dependency 'payments/payment'
require_dependency 'payments/payment_process'

module Payments
  def self.setup(config)
    @@command_bus = config.command_bus
    @@public_event_store = RailsEventStore::Client.new(
      repository: config.event_repository,
      mapper: RubyEventStore::Mappers::Default.new(
        events_class_remapping: events_class_remapping
      ),
      dispatcher: RubyEventStore::ComposedDispatcher.new(
        RubyEventStore::ImmediateAsyncDispatcher.new(scheduler: RailsEventStore::ActiveJobScheduler.new(serializer: JSON)),
        RubyEventStore::Dispatcher.new),
    )
    @@module_event_store = RailsEventStore::Client.new(
      repository: RailsEventStoreActiveRecord::EventRepository.new(
        model_factory: RailsEventStoreActiveRecord::WithAbstractBaseClass.new(Payments::ApplicationRecord), serializer: JSON),
      dispatcher: RubyEventStore::ComposedDispatcher.new(
        RubyEventStore::ImmediateAsyncDispatcher.new(scheduler: RailsEventStore::ActiveJobScheduler.new(serializer: JSON)),
        RubyEventStore::Dispatcher.new),
    )

    # Subscribe public event handlers below
    public_event_store.tap do |store|
      store.subscribe(InitiatePayment.new(command_bus), to: ['new-order'])
    end

    # Subscribe private event handlers below
    event_store.tap do |store|
      store.subscribe(PaymentProcess.new(store, command_bus), to: [
        PaymentAuthorized,
        PaymentCaptured,
        PaymentExpired,
      ])
    end

    # Register commands handled by this module below
    command_bus.tap do |bus|
      bus.register(Payments::AuthorizePayment, Payments::OnAuthorizePayment.new(event_store))
      bus.register(Payments::SetPaymentAsExpired, Payments::OnExpirePayment.new(event_store))
      bus.register(Payments::CapturePayment, Payments::OnCapturePayment.new(event_store))
      bus.register(Payments::ReleasePayment, Payments::OnReleasePayment.new(event_store))
      bus.register(Payments::CompletePayment, Payments::OnCompletePayment.new(public_event_store))
    end
  end

  def self.events_class_remapping
    {
      'new-order' => 'Payments::PaymentInitiated',
      'payment-completed' => 'Payments::PaymentCompleted',
    }
  end

  def self.command_bus
    @@command_bus rescue nil
  end

  def self.public_event_store
    @@public_event_store rescue nil
  end

  def self.event_store
    @@module_event_store rescue nil
  end

  def self.setup?
    command_bus && event_store && public_event_store
  end

  class PaymentInitiated < Event
    event_type 'new-order'
    attribute :order_id,    Types::UUID
    attribute :amount,      Types::Coercible::Decimal
  end

  class PaymentCompleted < Event
    event_type 'payment-completed'
    attribute :transaction_id,  Types::Coercible::String
    attribute :order_id,        Types::UUID
  end
end
