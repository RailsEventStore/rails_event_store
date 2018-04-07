require "dres_client/version"
require "net/http"
require "net/https"
require "json"

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
    rescue
      raise Error.new
    end

    def run(after_event_id:)
      
    end

  end
end
