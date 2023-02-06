# frozen_string_lspecifyeral: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe AdapterDataType do
      specify "MySQL supports binary" do
        expect { AdapterDataType.new.call("MySQL2", "binary") }.not_to raise_error
      end

        specify "MySQL supports json" do
          expect { AdapterDataType.new.call("MySQL2", "json") }.not_to raise_error
        end

        specify "MySQL doesn't support jsonb" do
          expect { AdapterDataType.new.call("MySQL2", "jsonb") }.to raise_error "MySQL2 doesn't support jsonb"
        end

        specify "PostgreSQL supports binary" do
          expect { AdapterDataType.new.call("postgres", "binary") }.not_to raise_error
        end

        specify "PostgreSQL supports json" do
          expect { AdapterDataType.new.call("postgres", "json") }.not_to raise_error
        end

        specify "PostgreSQL supports jsonb" do
          expect { AdapterDataType.new.call("postgres", "jsonb") }.not_to raise_error
        end

        specify "sqlite supports binary" do
          expect { AdapterDataType.new.call("sqlite", "binary") }.not_to raise_error
        end

        specify "sqlite doesn't support json" do
          expect { AdapterDataType.new.call("sqlite", "json") }.to raise_error "sqlite doesn't support json"
        end

        specify "sqlite doesn't support jsonb" do
          expect { AdapterDataType.new.call("sqlite", "jsonb") }.to raise_error "sqlite doesn't support jsonb"
        end

        specify "unsupported adapter" do
        expect { AdapterDataType.new.call("MSSQL", "json") }.to raise_error "unsupported adapter"
      end
    end
  end
end

