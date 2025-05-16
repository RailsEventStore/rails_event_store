# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Browser
    ::RSpec.describe Router do
      specify "params from multiple route segments" do
        request = mock_request("GET", "/some/foo/bar")
        expect do |probe|
          router = Router.new
          router.add_route("GET", "/some/:funky/:segment", &probe)
          router.handle(request)
        end.to yield_with_args({ "funky" => "foo", "segment" => "bar" }, urls.with_request(request))
      end

      specify "encoded params" do
        request = mock_request("GET", "/foo%2Dbar.xml")
        expect do |probe|
          router = Router.new
          router.add_route("GET", "/:try_me", &probe)
          router.handle(request)
        end.to yield_with_args({ "try_me" => "foo-bar.xml" }, urls.with_request(request))
      end

      specify "route params and query params" do
        request = mock_request("GET", "/dont?try=me")
        expect do |probe|
          router = Router.new
          router.add_route("GET", "/:try_me", &probe)
          router.handle(request)
        end.to yield_with_args({ "try_me" => "dont", "try" => "me" }, urls.with_request(request))
      end

      specify "not found by path" do
        expect do
          router = Router.new
          router.add_route("GET", "/some", &no_op)
          router.handle(mock_request("GET", "/none"))
        end.to raise_error(Router::NoMatch)
      end

      specify "not found by method" do
        expect do
          router = Router.new
          router.add_route("GET", "/some", &no_op)
          router.handle(mock_request("POST", "/some"))
        end.to raise_error(Router::NoMatch)
      end

      specify "root route when mounted" do
        router = Router.new
        router.add_route("GET", "/", &no_content)

        response =
          Rack::MockRequest.new(
            Rack::Builder.new do
              map "/mounted" do
                run ->(env) { router.handle(Rack::Request.new(env)) }
              end
            end,
          ).get("/mounted")
        expect(response).to be_no_content
      end

      def urls
        Urls.initial
      end

      def no_content
        Proc.new { [204, {}, []] }
      end

      def no_op
        Proc.new {}
      end

      def mock_request(method, path)
        Rack::Request.new(Rack::MockRequest.env_for(path, method: method))
      end
    end
  end
end
