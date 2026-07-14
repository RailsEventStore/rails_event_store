# frozen_string_literal: true

module RailsEventStore
  module HotwireBrowser
    class EventsController < ApplicationController
      def show
        event = event_store.read.event!(params.fetch(:id))

        metadata = event.metadata.to_h
        %i[timestamp valid_at].each do |key|
          metadata[key] = metadata.fetch(key).iso8601(RubyEventStore::TIMESTAMP_PRECISION) if metadata.key?(key)
        end

        parent_event = (event_store.read.event(event.metadata.fetch(:causation_id)) if event.metadata.key?(:causation_id))

        render :show,
               formats: [:html],
               locals: {
                 event: event,
                 metadata: metadata,
                 streams: event_store.streams_of(event.event_id).map(&:name).sort,
                 parent_event: parent_event,
                 caused_by: event_store.read.stream("$by_causation_id_#{event.event_id}").backward.to_a,
               }
      end
    end
  end
end
