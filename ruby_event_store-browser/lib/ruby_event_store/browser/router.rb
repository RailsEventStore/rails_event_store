# frozen_string_literal: true

module RubyEventStore
  module Browser
    class Router
      NoMatch = Class.new(StandardError)

      class Route
        NAMED_SEGMENTS_PATTERN = %r{\/([^\/]*):([^:$\/]+)}.freeze
        private_constant :NAMED_SEGMENTS_PATTERN

        def initialize(request_method, pattern, &block)
          @request_method = request_method
          @pattern = pattern
          @handler = block
        end

        def match(request)
          return unless request.request_method.eql?(request_method)

          match_data = regexp.match(File.join("/", request.path_info))
          if match_data
            match_data.named_captures.transform_values do |v|
              Rack::Utils.unescape(v)
            end
          end
        end

        def call(params, urls)
          handler[params, urls]
        end

        private

        def regexp
          /\A#{pattern.gsub(NAMED_SEGMENTS_PATTERN, '/\1(?<\2>[^$/]+)')}\Z/
        end

        attr_reader :request_method, :pattern, :handler
      end

      def initialize(urls = Urls.initial)
        @routes = Array.new
        @urls = urls
      end

      def add_route(request_method, pattern, &block)
        routes << Route.new(request_method, pattern, &block)
      end

      def handle(request)
        routes.each do |route|
          route_params = route.match(request)
          if route_params
            return(
              route.call(
                request.params.merge(route_params),
                urls.with_request(request)
              )
            )
          end
        end
        raise NoMatch
      end

      private

      attr_reader :routes, :urls
    end
  end
end
