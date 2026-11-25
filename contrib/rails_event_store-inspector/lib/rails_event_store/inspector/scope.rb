# frozen_string_literal: true

require "securerandom"

module RailsEventStore
  module Inspector
    class Scope
      COOKIE = "res_inspector_id"

      Resolved = Struct.new(:key, :set_cookie)

      def initialize(configured = nil)
        @configured = configured
      end

      def call(env)
        return Resolved.new(@configured.call(env), nil) if @configured

        existing = cookie(env, COOKIE)
        return Resolved.new(existing, nil) if existing

        fresh = SecureRandom.hex(16)
        Resolved.new(fresh, "#{COOKIE}=#{fresh}; Path=/; HttpOnly; SameSite=Lax")
      end

      private

      def cookie(env, name)
        env["HTTP_COOKIE"].to_s.split(/;\s*/).each do |pair|
          key, value = pair.split("=", 2)
          return value if key == name && value && !value.empty?
        end
        nil
      end
    end
  end
end
