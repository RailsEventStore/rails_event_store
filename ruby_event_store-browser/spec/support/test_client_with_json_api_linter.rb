require "rack/test"
require 'json-schema'

class TestClientWithJsonApiLinter
  include Rack::Test::Methods

  class InvalidContentType < StandardError
    def initialize(content_type)
      super(<<~EOS)
          expected: Content-Type: application/vnd.api+json
          got:      Content-Type: #{content_type}
      EOS
    end
  end

  class InvalidDocument < StandardError
    def initialize(document)
      super(JSON::Validator.fully_validate(File.join(__dir__, "schema.json"), document).join("\n"))
    end
  end

  def initialize(app, host = 'example.org')
    @app  = app
    @host = host
  end

  def get(*)
    header "Content-Type", "application/vnd.api+json"
    super
  end

  def parsed_body
    JSON.parse(last_response.body)
  end

  private

  def build_rack_mock_session
    Rack::MockSession.new(app, host).tap do |session|
      session.after_request { validate_request }
      session.after_request { validate_response }
    end
  end

  attr_reader :app, :host

  def validate_response
    return if last_response.body.empty?
    raise InvalidContentType.new(last_response.content_type) unless match_content_type(last_response.content_type)

    document = JSON.parse(last_response.body.dup)
    raise InvalidDocument.new(document) unless valid_schema(document)
  end

  def validate_request
    raise InvalidContentType.new(last_request.content_type) unless match_content_type(last_request.content_type)

    document = last_request.body.read
    last_request.body.rewind

    raise InvalidDocument.new(document) unless valid_schema(document)
  end

  def valid_schema(document)
    return true unless document.to_s.size > 0
    JSON::Validator.validate(File.join(__dir__, "schema.json"), document)
  end

  def match_content_type(content_type)
    /application\/vnd\.api\+json/.match(content_type)
  end
end
