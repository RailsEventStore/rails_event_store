require "ruby_event_store"
require "dres_rails"
require "./dres_app"

STDOUT.sync  = true
logger       = Logger.new(STDOUT)
logger.level = Logger::INFO

client = DresClient::Http.new(
  mapper:  RubyEventStore::Mappers::Default.new,
  uri:     URI.parse(ENV.fetch("DRES_URL")),
  api_key: ENV.fetch("DRES_API_KEY"),
)

handlers = [
  ->(event) { logger.info("got event: #{event}") }
]

app = DresApp.new(
  client:    client,
  logger:    logger,
  processor: proc do |event|
    handlers.each do |handler|
      begin
        handler.(event)
      rescue => doh
        logger.error("oh no!: #{doh.message}")
      end
    end
  end,
)

catch(:exit_now) do
  app.trap_signals
  app.run
end
