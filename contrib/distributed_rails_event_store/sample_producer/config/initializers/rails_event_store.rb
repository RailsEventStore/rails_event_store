require 'rails_event_store'
require 'aggregate_root'
require 'arkency/command_bus'

Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new(repository: RailsEventStoreActiveRecord::PgLinearizedEventRepository.new)
  Rails.configuration.command_bus = Arkency::CommandBus.new

  AggregateRoot.configure do |config|
    config.default_event_store = Rails.configuration.event_store
  end

  # Subscribe event handlers below
  # Rails.configuration.event_store.tap do |store|
  #   store.subscribe(InvoiceReadModel.new, to: [InvoicePrinted])
  #   store.subscribe(->(event) { SendOrderConfirmation.new.call(event) }, to: [OrderSubmitted])
  #   store.subscribe_to_all_events(->(event) { Rails.logger.info(event.type) })
  # end

  # Register command handlers below
  # Rails.configuration.command_bus.tap do |bus|
  #   bus.register(PrintInvoice, Invoicing::OnPrint.new)
  #   bus.register(SubmitOrder,  ->(cmd) { Ordering::OnSubmitOrder.new.call(cmd) })
  # end
end
