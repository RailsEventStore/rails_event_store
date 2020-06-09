require 'spec_helper'

module RubyEventStore
  module Outbox
    class CLI
      RSpec.describe Parser do
        specify "#parse" do
          argv = [
            '--database-url=mysql2://root@0.0.0.0:3306/dbname',
            '--redis-url=redis://localhost:6379/0'
          ]

          options = Parser.parse(argv)

          expect(options.database_url).to eq("mysql2://root@0.0.0.0:3306/dbname")
          expect(options.redis_url).to eq("redis://localhost:6379/0")
        end
      end
    end
  end
end
