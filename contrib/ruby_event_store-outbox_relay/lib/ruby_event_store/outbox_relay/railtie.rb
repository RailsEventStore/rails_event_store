# frozen_string_literal: true

require "rails/railtie"

module RubyEventStore
  module OutboxRelay
    class Railtie < ::Rails::Railtie
      rake_tasks { load File.expand_path("../../tasks/outbox_relay.rake", __dir__) }
    end
  end
end
