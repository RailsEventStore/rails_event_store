require "rack/test"

class WebClient
  include Rack::Test::Methods

  def initialize(app, host = "example.org")
    @app = app
    @host = host
  end

  def get(*)
    header "content-type", "application/vnd.api+json"
    super
  end

  def parsed_body
    JSON.parse(last_response.body)
  end

  private

  def build_rack_mock_session
    Rack::MockSession.new(Rack::Lint.new(app), host)
  end

  attr_reader :app, :host
end
