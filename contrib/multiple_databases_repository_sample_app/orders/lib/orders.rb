# frozen_string_literal: true

require_relative 'orders/application_record'
require_relative '../../lib/event'
require_relative '../../lib/types'
require_relative '../../lib/command'
require_relative '../../lib/command_handler'

require_dependency 'orders/add_item_to_basket'
require_dependency 'orders/fake_number_generator'
require_dependency 'orders/item_added_to_basket'
require_dependency 'orders/item_removed_from_basket'
require_dependency 'orders/number_generator'
require_dependency 'orders/on_add_item_to_basket'
require_dependency 'orders/on_remove_item_from_basket'
require_dependency 'orders/on_set_order_as_expired'
require_dependency 'orders/on_mark_order_as_paid'
require_dependency 'orders/on_submit_order'
require_dependency 'orders/order'
require_dependency 'orders/order_expired'
require_dependency 'orders/order_paid'
require_dependency 'orders/order_line'
require_dependency 'orders/order_submitted'
require_dependency 'orders/remove_item_from_basket'
require_dependency 'orders/set_order_as_expired'
require_dependency 'orders/mark_order_as_paid'
require_dependency 'orders/submit_order'

module Orders
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
        Orders::ApplicationRecord),
      mapper: RubyEventStore::Mappers::Default.new(serializer: JSON)
    )

    # Subscribe public event handlers below
    public_event_store.tap do |store|
#      store.subscribe(MarkAsPaid.new, to: [Paid])
#      store.subscribe(RequestPayment.new, to: [PaymentFailed])
    end

    # Register commands handled by this module below
    command_bus.tap do |bus|
      bus.register(Orders::SubmitOrder, Orders::OnSubmitOrder.new(event_store, number_generator_factory: config.number_generator_factory))
      bus.register(Orders::SetOrderAsExpired, Orders::OnSetOrderAsExpired.new(event_store))
      bus.register(Orders::MarkOrderAsPaid, Orders::OnMarkOrderAsPaid.new(event_store))
      bus.register(Orders::AddItemToBasket, Orders::OnAddItemToBasket.new(event_store))
      bus.register(Orders::RemoveItemFromBasket, Orders::OnRemoveItemFromBasket.new(event_store))
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

  def self.setup?
    command_bus && event_store && public_event_store
  end
end
