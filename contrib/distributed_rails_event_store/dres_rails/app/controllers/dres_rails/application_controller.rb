module DresRails
  class ApplicationController < ActionController::Base
    class NULL
      def self.serialized_record_to_event(record)
        record
      end
    end
    private_constant :NULL

    def index
      spec   = build_initial_spec
      spec   = spec.limit(1000)
      spec   = spec.from(after) if after
      events = spec.each.map(&:to_h)

      render json: {
        after:  after || "head",
        events: events,
      }
    end

    private

    def build_initial_spec
      repository = Rails.configuration.event_store.send(:repository)
      RubyEventStore::Specification.new(RubyEventStore::SpecificationReader.new(repository, NULL))
    end

    def after
      params[:after_event_id]
    end
  end
end