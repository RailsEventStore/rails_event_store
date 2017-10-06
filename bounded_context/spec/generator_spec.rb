require 'spec_helper'


module BoundedContext
  RSpec.describe Generator do
    RSpec::Matchers.define :match_content do |expected|
      match do |actual|
        File.read(File.join(destination_root, actual)).match(expected)
      end
    end

    specify do
      run_generator %w[payments]

      expect('payments/lib/payments.rb').to match_content(<<-EOF)
module Payments
end
EOF

      expect('config/application.rb').to match_content(<<-EOF)
  config.paths.add 'payments/lib', eager_load: true
EOF
    end

    specify do
      run_generator %w[Inventory]

      expect('inventory/lib/inventory.rb').to match_content(<<-EOF)
module Inventory
end
EOF

      expect('config/application.rb').to match_content(<<-EOF)
  config.paths.add 'inventory/lib', eager_load: true
EOF
    end

    specify do
      run_generator %w[mumbo_jumbo]

      expect('mumbo_jumbo/lib/mumbo_jumbo.rb').to match_content(<<-EOF)
module MumboJumbo
end
EOF

      expect('config/application.rb').to match_content(<<-EOF)
  config.paths.add 'mumbo_jumbo/lib', eager_load: true
EOF
    end
  end
end
