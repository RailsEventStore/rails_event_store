require 'spec_helper'
require 'active_support/core_ext/string/strip'

module BoundedContext
  RSpec.describe Generator do
    RSpec::Matchers.define :match_content do |expected|
      match do |actual|
        File.read(File.join(destination_root, actual)).match(expected)
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
  end
end
