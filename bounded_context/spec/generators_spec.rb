# frozen_string_literal: true

require 'spec_helper'
require 'generators/bounded_context/bounded_context_generator'

module BoundedContext
  module Generators
    RSpec.describe BoundedContextGenerator do
      RSpec::Matchers.define :match_content do |expected|
        match do |actual|
          @matcher = ::RSpec::Matchers::BuiltIn::Match.new(expected)
          @matcher.matches?(File.read(File.join(destination_root, actual)))
        end

        failure_message do
          @matcher.failure_message
        end
      end

      RSpec::Matchers.define :exists_at_destination_path do |_|
        match do |actual|
          @matcher = ::RSpec::Matchers::BuiltIn::Exist.new(File.join(destination_root, actual))
          @matcher.matches?(File)
        end

        failure_message do
          @matcher.failure_message
        end
      end

      specify do
        run_generator %w[payments]

        expect('payments/lib/payments.rb').to match_content(<<~EOF)
          module Payments
          end
        EOF
        expect('config/application.rb').to match_content(<<~EOF)
          config.paths.add 'payments/lib', eager_load: true
        EOF
      end

      specify do
        run_generator %w[Inventory]

        expect('inventory/lib/inventory.rb').to match_content(<<~EOF)
          module Inventory
          end
        EOF
        expect('config/application.rb').to match_content(<<~EOF)
          config.paths.add 'inventory/lib', eager_load: true
        EOF
      end

      specify do
        run_generator %w[mumbo_jumbo]

        expect('mumbo_jumbo/lib/mumbo_jumbo.rb').to match_content(<<~EOF)
          module MumboJumbo
          end
        EOF
        expect('config/application.rb').to match_content(<<~EOF)
          config.paths.add 'mumbo_jumbo/lib', eager_load: true
        EOF
      end

      specify do
        run_generator %w[identity_access --test_framework=rspec]

        expect_identity_access_spec_helper
        expect_identity_access_bc_spec
        expect_identity_access_require_bc_spec
      end

      specify do
        run_generator %w[IdentityAccess --test_framework=rspec]

        expect_identity_access_spec_helper
        expect_identity_access_bc_spec
        expect_identity_access_require_bc_spec
      end

      specify do
        run_generator %w[identity_access --test-framework=test_unit]
        expect_identity_access_test_helper
      end

      specify do
        run_generator %w[IdentityAccess --test-framework=test_unit]
        expect_identity_access_test_helper
      end

      specify do
        system_run_generator %w[IdentityAccess]
        expect_identity_access_test_helper
      end


      specify do
        run_generator %w[identity_access]

        expect('identity_access/lib/identity_access/.keep').to exists_at_destination_path
      end


      def expect_identity_access_spec_helper
        expect('identity_access/spec/spec_helper.rb').to match_content(<<~EOF)
          ENV['RAILS_ENV'] = 'test'

          $LOAD_PATH.push File.expand_path('../../../spec', __FILE__)
          require File.expand_path('../../../config/environment', __FILE__)
          require File.expand_path('../../../spec/rails_helper', __FILE__)

          require_relative '../lib/identity_access'
        EOF
      end

      def expect_identity_access_bc_spec
        expect('identity_access/spec/identity_access_spec.rb').to match_content(<<~EOF)
          require_relative 'spec_helper'

          RSpec.describe IdentityAccess do
          end
        EOF
      end

      def expect_identity_access_require_bc_spec
        expect('spec/identity_access_spec.rb').to match_content(<<~'EOF')
          require 'rails_helper'

          path = Rails.root.join('identity_access/spec')
          Dir.glob("#{path}/**/*_spec.rb") do |file|
            require file
          end
        EOF
      end

      def expect_identity_access_test_helper
        expect('identity_access/test/test_helper.rb').to match_content(<<~EOF)
          require_relative '../lib/identity_access'
        EOF
      end
    end
  end
end
