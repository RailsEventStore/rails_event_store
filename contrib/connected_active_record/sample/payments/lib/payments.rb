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
    # config.event_store.tap do |store|
    #   store.subscribe(StartPaymentProcess.new, to: [OrderSubmitted])
    # end

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
    {}
  end
end
