# frozen_string_literal: true

class CspApp
  def initialize(app, policy)
    @app = app
    @policy = policy
  end

  def call(env)
    status, headers, response = @app.call(env)

    headers["content-security-policy"] = @policy
    [status, headers, response]
  end
end
