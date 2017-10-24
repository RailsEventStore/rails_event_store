require 'spec_helper'
require 'active_support/core_ext/string/strip'
require 'generators/bounded_context/bounded_context_generator'

module BoundedContext
  RSpec.describe Generators do
    RSpec::Matchers.define :match_content do |expected|
      match do |actual|
        @matcher = ::RSpec::Matchers::BuiltIn::Match.new(expected)
        @matcher.matches?(File.read(File.join(destination_root, actual)))
      end

      failure_message do
        @matcher.failure_message
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
        ENV['RAILS_ENV'] = 'test'

        $LOAD_PATH.push File.expand_path('../../../spec', __FILE__)
        require File.expand_path('../../../config/environment', __FILE__)
        require File.expand_path('../../../spec/rails_helper', __FILE__)
        
        require_relative '../lib/identity_access'
      EOF

      expect('identity_access/spec/identity_access_spec.rb').to match_content(<<-EOF.strip_heredoc)
        require_relative 'spec_helper'

        RSpec.describe IdentityAccess do
        end
      EOF
    end

    specify do
      run_generator %w[IdentityAccess --test_framework=rspec]

      expect('identity_access/spec/spec_helper.rb').to match_content(<<-EOF.strip_heredoc)
        ENV['RAILS_ENV'] = 'test'

        $LOAD_PATH.push File.expand_path('../../../spec', __FILE__)
        require File.expand_path('../../../config/environment', __FILE__)
        require File.expand_path('../../../spec/rails_helper', __FILE__)
        
        require_relative '../lib/identity_access'
      EOF

      expect('identity_access/spec/identity_access_spec.rb').to match_content(<<-EOF.strip_heredoc)
        require_relative 'spec_helper'

        RSpec.describe IdentityAccess do
        end
      EOF
    end

    specify do
      run_generator %w[identity_access --test-framework=test_unit]

      expect('identity_access/test/test_helper.rb').to match_content(<<-EOF.strip_heredoc)
        require_relative '../lib/identity_access'
      EOF
    end

    specify do
      run_generator %w[IdentityAccess --test-framework=test_unit]

      expect('identity_access/test/test_helper.rb').to match_content(<<-EOF.strip_heredoc)
        require_relative '../lib/identity_access'
      EOF
    end

    specify do
      system_run_generator %w[IdentityAccess]

      expect('identity_access/test/test_helper.rb').to match_content(<<-EOF.strip_heredoc)
        require_relative '../lib/identity_access'
      EOF
    end
  end
end
