# frozen_string_literal: true

require_relative 'payments/application_record'
require_relative '../../lib/event'
require_relative '../../lib/types'
require_relative '../../lib/command'
require_relative '../../lib/command_handler'

require_dependency 'payments/payment_authorized'
require_dependency 'payments/payment_captured'
require_dependency 'payments/payment_released'
require_dependency 'payments/payment'

module Payments
  def self.setup(config)
    @@command_bus = config.command_bus
    @@public_event_store = RailsEventStore::Client.new(
      repository: config.event_repository,
      mapper: RubyEventStore::Mappers::Default.new(
        serializer: JSON,
        events_class_remapping: events_class_remapping
      )
    )
    @@module_event_store = RailsEventStore::Client.new(
      repository: RailsEventStoreActiveRecord::EventRepository.new(
        Payments::ApplicationRecord),
      mapper: RubyEventStore::Mappers::Default.new(serializer: JSON)
    )

    # Subscribe public event handlers below
    public_event_store.tap do |store|
#      store.subscribe(Authorize.new, to: [Initiated])
    end

    # Register commands handled by this module below
    command_bus.tap do |bus|
      bus.register(Payments::AuthorizePayment, Payments::OnAuthorizePayment.new(event_store))
      bus.register(Payments::CapturePayment, Payments::OnCapturePayment.new(event_store))
      bus.register(Payments::ReleasePayment, Payments::OnReleasePayment.new(event_store))
    end
  end

  def self.events_class_remapping
    {}
  end

  def self.command_bus
    @@command_bus
  end

  def self.public_event_store
    @@public_event_store
  end

  def self.event_store
    @@module_event_store
  end
end
