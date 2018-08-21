require 'json-schema'

class JsonApiLint
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

  def initialize(app)
    @app = app
  end

  def call(env)
    request  = Rack::Request.new(env)
    status, headers, body = @app.call(env)
    
    response = Rack::Response.new(body, status, headers)
    
    validate_request(request)
    validate_response(response)

    response
  ensure
    body.close if body.respond_to?(:close)
  end

  private

  def validate_response(response)
    raise InvalidContentType.new(response.content_type) unless match_content_type(response.content_type)

    document = JSON.parse(response.body.dup.join)
    raise InvalidDocument.new(document) unless valid_schema(document)
  end

  def validate_request(request)
    raise InvalidContentType.new(request.content_type) unless match_content_type(request.content_type)

    document = request.body.read
    request.body.rewind

    raise InvalidDocument.new(document) unless valid_schema(document)
  end

  def valid_schema(document)
    return true unless document.to_s.size > 0
    JSON::Validator.validate(File.join(__dir__, "schema.json"), document)
  end

  def match_content_type(content_type)
    /application\/vnd\.api\+json/.match?(content_type)
  end
end
