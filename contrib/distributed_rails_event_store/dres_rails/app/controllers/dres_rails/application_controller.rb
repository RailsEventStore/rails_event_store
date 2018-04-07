module DresRails
  class ApplicationController < ActionController::Base
    def index
      r = PostgresqlQueue::Reader.new(DistributedRepository.new)
      events = r.events(after_event_id: params[:after_event_id]).map do |serialized_record|
        serialized_record.to_h
      end
      render json: {
        events: events,
      }
    end
  end
end