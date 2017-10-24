require 'spec_helper'
require 'active_support/core_ext/string/strip'

module BoundedContext
  RSpec.describe Generators do
    RSpec::Matchers.define :match_content do |expected|
      match do |actual|
        content = File.read(File.join(destination_root, actual))
        content.match(expected)
      end
    end

    specify do
      run_generator %w[payments]

      expect('payments/lib/payments.rb').to match_content(<<-EOF.strip_heredoc)
        module Payments
        end
      EOF

      expect('config/application.rb').to match_content(<<-EOF.strip_heredoc)
        config.paths.add 'payments/lib', eager_load: true
      EOF
    end

    specify do
      run_generator %w[Inventory]

      expect('inventory/lib/inventory.rb').to match_content(<<-EOF.strip_heredoc)
        module Inventory
        end
      EOF

      expect('config/application.rb').to match_content(<<-EOF.strip_heredoc)
        config.paths.add 'inventory/lib', eager_load: true
      EOF
    end

    specify do
      run_generator %w[mumbo_jumbo]

      expect('mumbo_jumbo/lib/mumbo_jumbo.rb').to match_content(<<-EOF.strip_heredoc)
        module MumboJumbo
        end
      EOF

      expect('config/application.rb').to match_content(<<-EOF.strip_heredoc)
        config.paths.add 'mumbo_jumbo/lib', eager_load: true
      EOF
    end

    specify do
      run_generator %w[identity_access --test_framework=rspec]

      expect('identity_access/spec/spec_helper.rb').to match_content(<<-EOF.strip_heredoc)
        require_relative '../lib/identity_access'
      EOF
    end

    specify do
      run_generator %w[identity_access --test-framework=test_unit]

      expect('identity_access/test/test_helper.rb').to match_content(<<-EOF.strip_heredoc)
        require_relative '../lib/identity_access'
      EOF
    end
  end
end
