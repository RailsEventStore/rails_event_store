# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/helpers/subprocess_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe "lazy loading", mutant: false do
      include SubprocessHelper

      it { run_in_subprocess(<<~EOF) }
          require 'rails'
          require 'ruby_event_store/active_record'
          require 'active_record/railtie'

          Class.new(Rails::Application) do
            config.root = __dir__
            config.eager_load = false
            config.consider_all_requests_local = true
            config.secret_key_base = 'i_am_a_secret'

            initializer :repository do
              RubyEventStore::ActiveRecord::EventRepository.new(serializer: nil)
            end
          end.initialize!
        EOF
    end
  end
end
