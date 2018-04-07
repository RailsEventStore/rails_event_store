require "dres_client/version"
require "net/http"
require "net/https"
require "json"
require "ruby_event_store"

module DresClient
  class Http
    class Error < StandardError
    end

    def initialize(mapper:, uri:)
      @mapper = mapper
      @uri    = uri
    end

    def events(after_event_id:)
      uri = @uri.dup
      uri.query = URI.encode_www_form({after_event_id: after_event_id}) if after_event_id
      body = Net::HTTP.get(uri)
      json = JSON.parse(body)
      json["events"].map do |ev|
        serialized_record = RubyEventStore::SerializedRecord.new(
          metadata: yaml_empty_hash,
          **symbolize_keys(ev)
        )
        @mapper.serialized_record_to_event(serialized_record)
      end
    rescue
      raise Error.new
    end

    def run(after_event_id:)

    end

    private

    def yaml_empty_hash
      "--- {}\n"
    end

    def symbolize_keys(ev)
      ev.transform_keys(&:to_sym)
    end

  end
end
