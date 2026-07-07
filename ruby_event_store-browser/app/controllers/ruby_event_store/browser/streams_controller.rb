# frozen_string_literal: true

module RubyEventStore
  module Browser
    class StreamsController < ApplicationController
      def show
        stream_name = params.fetch(:id)
        reader = GetEventsFromStream.new(event_store: event_store, stream_name: stream_name, page: params[:page])

        render :show,
               formats: [:html],
               locals: {
                 stream_name: stream_name,
                 events: reader.events,
                 pagination: reader.pagination.transform_values { |cursor| stream_page_url(stream_name, cursor, reader.count) },
                 related_streams: related_streams(stream_name),
               }
      end

      private

      def related_streams(stream_name)
        Rails.configuration.x.ruby_event_store_browser_related_streams_query&.call(stream_name)
      end

      def stream_page_url(stream_name, cursor, count)
        query =
          URI.encode_www_form(
            [["page[position]", cursor[:position]], ["page[direction]", cursor[:direction]], ["page[count]", count]],
          )
        "#{stream_path(id: stream_name)}?#{query}"
      end
    end
  end
end
