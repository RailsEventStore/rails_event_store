require "dres_client/version"
require "net/http"
require "net/https"
require "json"
require "ruby_event_store"

module DresClient
  class Http
    class Error < StandardError
    end

    def initialize(mapper:, uri:, api_key:)
      @mapper = mapper
      @uri    = uri
      @api_key = api_key
    end

    def events(after_event_id:)
      uri = @uri.dup
      uri.query = URI.encode_www_form({after_event_id: after_event_id}) if after_event_id

      req = Net::HTTP::Get.new(uri)
      req['RES-Api-Key'] = @api_key
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: URI::HTTPS === uri) {|http|
        http.request(req)
      }
      raise Error unless Net::HTTPSuccess === res
      json = JSON.parse(res.body)
      json["events"].map do |ev|
        serialized_record = RubyEventStore::SerializedRecord.new(**symbolize_keys(ev))
        @mapper.serialized_record_to_event(serialized_record)
      end
    rescue
      raise Error.new
    end

    def drain(after_event_id:, &proc)
      run(after_event_id: after_event_id) do |events|
        break if events.empty?
        proc.call(events)
      end
    end

    def run(after_event_id:, &proc)
      loop do
        events = events(after_event_id: after_event_id)
        proc.call(events)
        after_event_id = events.last.event_id if events.last
      end
    end

    private

    def symbolize_keys(ev)
      ev.transform_keys(&:to_sym)
    end

  end
end
