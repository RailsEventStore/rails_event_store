require "rack/test"

class WebClient
  include Rack::Test::Methods

  def initialize(app, host = "example.org")
    @app = app
    @host = host
  end

  def get(*)
    super
  end

  private

  def build_rack_mock_session
    Rack::MockSession.new(Rack::Lint.new(app), host)
  end

  attr_reader :app, :host
end
