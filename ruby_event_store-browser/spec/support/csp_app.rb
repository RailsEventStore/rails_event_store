class CspApp
  def initialize(app, policy)
    @app = app
    @policy = policy
  end

  def call(env)
    status, headers, response = @app.call(env)

    headers["Content-Security-Policy"] = @policy
    [status, headers, response]
  end
end
