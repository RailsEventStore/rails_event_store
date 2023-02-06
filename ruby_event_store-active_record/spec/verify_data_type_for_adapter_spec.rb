# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe VerifyDataTypeForAdapter do
      specify "MySQL supports binary" do
        expect { VerifyDataTypeForAdapter.new.call("MySQL2", "binary") }.not_to raise_error
      end

        specify "MySQL supports json" do
          expect { VerifyDataTypeForAdapter.new.call("MySQL2", "json") }.not_to raise_error
        end

        specify "MySQL doesn't support jsonb" do
          expect { VerifyDataTypeForAdapter.new.call("MySQL2", "jsonb") }.to raise_error InvalidDataTypeForAdapter,"MySQL2 doesn't support jsonb"
        end

        specify "PostgreSQL supports binary" do
          expect { VerifyDataTypeForAdapter.new.call("PostgreSQL", "binary") }.not_to raise_error
        end

        specify "PostgreSQL supports json" do
          expect { VerifyDataTypeForAdapter.new.call("PostgreSQL", "json") }.not_to raise_error
        end

        specify "PostgreSQL supports jsonb" do
          expect { VerifyDataTypeForAdapter.new.call("PostgreSQL", "jsonb") }.not_to raise_error
        end

        specify "PostgreSQL doesn't support bla" do
          expect { VerifyDataTypeForAdapter.new.call("PostgreSQL", "bla") }.to raise_error InvalidDataTypeForAdapter,"PostgreSQL doesn't support bla"
        end

        specify "sqlite supports binary" do
          expect { VerifyDataTypeForAdapter.new.call("SQLite", "binary") }.not_to raise_error
        end

        specify "sqlite doesn't support json" do
          expect { VerifyDataTypeForAdapter.new.call("SQLite", "json") }.to raise_error InvalidDataTypeForAdapter,"sqlite doesn't support json"
        end

        specify "sqlite doesn't support jsonb" do
          expect { VerifyDataTypeForAdapter.new.call("SQLite", "jsonb") }.to raise_error InvalidDataTypeForAdapter, "sqlite doesn't support jsonb"
        end

        specify "unsupported adapter" do
        expect { VerifyDataTypeForAdapter.new.call("MSSQL", "json") }.to raise_error UnsupportedAdapter, "Unsupported adapter"
      end
    end
  end
end

