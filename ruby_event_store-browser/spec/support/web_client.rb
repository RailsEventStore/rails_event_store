# frozen_string_literal: true

class WebClient
  extend Forwardable
  def_delegators :@session, :get, :post

  def initialize(app, host = "example.org")
    @session = Rack::MockSession.new(Rack::Lint.new(app), host)
  end
end
