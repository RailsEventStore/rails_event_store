# frozen_string_literal: true

module RailsEventStore
  module Inspector
    ::RSpec.describe Scope do
      describe "the built-in cookie" do
        specify "mints one for a visitor who has none" do
          resolved = Scope.new.call({})

          expect(resolved.key).to match(/\A\h{32}\z/)
          expect(resolved.set_cookie).to include("res_inspector_id=#{resolved.key}")
        end

        specify "the cookie is not readable from scripts and does not travel cross-site" do
          expect(Scope.new.call({}).set_cookie).to include("HttpOnly", "SameSite=Lax", "Path=/")
        end

        specify "reuses the one a visitor already has" do
          resolved = Scope.new.call("HTTP_COOKIE" => "res_inspector_id=abc123")

          expect(resolved.key).to eq("abc123")
          expect(resolved.set_cookie).to be_nil
        end

        specify "picks its own cookie out of the application's" do
          env = { "HTTP_COOKIE" => "_session_id=xyz; res_inspector_id=abc123; other=1" }

          expect(Scope.new.call(env).key).to eq("abc123")
        end

        specify "two visitors get different keys" do
          first = Scope.new.call({}).key
          second = Scope.new.call({}).key

          expect(first).not_to eq(second)
        end

        specify "an empty cookie counts as none" do
          resolved = Scope.new.call("HTTP_COOKIE" => "res_inspector_id=")

          expect(resolved.key).to match(/\A\h{32}\z/)
        end
      end

      describe "a configured scope" do
        specify "is used instead, and mints no cookie of ours" do
          resolved = Scope.new(->(env) { env["user_id"] }).call("user_id" => 42)

          expect(resolved.key).to eq(42)
          expect(resolved.set_cookie).to be_nil
        end

        specify "sees the request, so it can key by session or by user" do
          scope = Scope.new(->(env) { "session-#{env["rack.session_id"]}" })

          expect(scope.call("rack.session_id" => "s1").key).to eq("session-s1")
        end
      end
    end
  end
end
