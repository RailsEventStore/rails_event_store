# frozen_string_literal: true

require_relative 'orders/application_record'
require_relative '../../lib/event'
require_relative '../../lib/types'
require_relative '../../lib/command'
require_relative '../../lib/command_handler'

require_dependency 'orders/add_item_to_basket'
require_dependency 'orders/remove_item_from_basket'
require_dependency 'orders/submit_order'

require_dependency 'orders/item_added_to_basket'
require_dependency 'orders/item_removed_from_basket'
require_dependency 'orders/order_submitted'

require_dependency 'orders/on_add_item_to_basket'
require_dependency 'orders/on_remove_item_from_basket'
require_dependency 'orders/on_submit_order'

require_dependency 'orders/order'
require_dependency 'orders/order_line'
require_dependency 'orders/number_generator'
require_dependency 'orders/fake_number_generator'

module Orders
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
        model_factory: RailsEventStoreActiveRecord::WithAbstractBaseClass.new(Orders::ApplicationRecord), serializer: JSON),
      dispatcher: RubyEventStore::ComposedDispatcher.new(
        RubyEventStore::ImmediateAsyncDispatcher.new(scheduler: RailsEventStore::ActiveJobScheduler.new(serializer: JSON)),
        RubyEventStore::Dispatcher.new),
    )

    # Subscribe public event handlers below
    public_event_store.tap do |store|
    end

    # Subscribe private event handlers below
    event_store.tap do |store|
      store.subscribe(PrepareOrderProcess.new(store, command_bus), to: [
        ItemAddedToBasket,
        ItemRemovedFromBasket,
        OrderSubmitted,
      ])
    end

    # Register commands handled by this module below
    command_bus.tap do |bus|
      bus.register(Orders::SubmitOrder, Orders::OnSubmitOrder.new(event_store, number_generator_factory: config.number_generator_factory))
      bus.register(Orders::AddItemToBasket, Orders::OnAddItemToBasket.new(event_store))
      bus.register(Orders::RemoveItemFromBasket, Orders::OnRemoveItemFromBasket.new(event_store))
      bus.register(Orders::PlaceOrder, ->(cmd) { public_event_store.publish(OrderPlaced.new(**cmd)) })
    end
  end

  def self.events_class_remapping
    {
      'new-order' => 'Orders::OrderPlaced',
    }
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

  class OrderPlaced < Event
    event_type 'new-order'
    attribute :order_id, Types::UUID
    attribute :customer_id, Types::ID
    attribute :delivery_address_id, Types::ID
    attribute :payment_method_id, Types::ID
    attribute :amount, Types::Coercible::Decimal
  end
end
