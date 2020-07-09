require "rack/test"

class TestClient
  include Rack::Test::Methods

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
    Rack::MockSession.new(app, host)
  end

  attr_reader :app, :host
end
