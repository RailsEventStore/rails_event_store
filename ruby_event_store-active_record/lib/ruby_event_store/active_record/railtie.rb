# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class Railtie < ::Rails::Railtie
      initializer "ruby_event_store-active_record" do
        ActiveSupport.on_load(:active_record) do
          require_relative "../active_record/skip_json_serialization"
          require_relative "../active_record/event"
        end
      end
    end
  end
end
