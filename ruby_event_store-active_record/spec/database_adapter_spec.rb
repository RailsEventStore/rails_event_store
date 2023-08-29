# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe DatabaseAdapter do
      specify "from_string" do
        expect(DatabaseAdapter.from_string("PostgreSQL")).to eql(DatabaseAdapter::PostgreSQL.new)
        expect(DatabaseAdapter.from_string("PostGIS")).to eql(DatabaseAdapter::PostgreSQL.new)
        expect(DatabaseAdapter.from_string("MySQL2")).to eql(DatabaseAdapter::MySQL2.new)
        expect(DatabaseAdapter.from_string("SQLite")).to eql(DatabaseAdapter::SQLite.new)
      end

      specify "equality" do
        expect(DatabaseAdapter::PostgreSQL.new).not_to eql(DatabaseAdapter::MySQL2.new)
        expect(DatabaseAdapter::PostgreSQL.new).not_to eql("postgresql")
      end

      specify "adapter_name" do
        expect(DatabaseAdapter::PostgreSQL.new.adapter_name).to eql("postgresql")
        expect(DatabaseAdapter::MySQL2.new.adapter_name).to eql("mysql2")
        expect(DatabaseAdapter::SQLite.new.adapter_name).to eql("sqlite")
      end

      specify "raise on unknown adapter" do
        expect { DatabaseAdapter.from_string("kakadudu") }.to raise_error(
          UnsupportedAdapter,
          "Unsupported adapter: \"kakadudu\""
        )
        expect { DatabaseAdapter.from_string(nil) }.to raise_error(UnsupportedAdapter, "Unsupported adapter: nil")
        expect { DatabaseAdapter.from_string(123) }.to raise_error(UnsupportedAdapter, "Unsupported adapter: 123")
      end

      specify "unsupported data type passed to #from_string" do
        expect { DatabaseAdapter.from_string("postgresql", "foo") }.to raise_error(InvalidDataTypeForAdapter)
        expect { DatabaseAdapter.from_string("mysql2", "foo") }.to raise_error(InvalidDataTypeForAdapter)
        expect { DatabaseAdapter.from_string("sqlite", "foo") }.to raise_error(InvalidDataTypeForAdapter)
      end

      specify "hash" do
        expect(DatabaseAdapter::PostgreSQL.new.hash).to eql(DatabaseAdapter.hash ^ "postgresql".hash)
        expect(DatabaseAdapter::MySQL2.new.hash).to eql(DatabaseAdapter.hash ^ "mysql2".hash)
        expect(DatabaseAdapter::SQLite.new.hash).to eql(DatabaseAdapter.hash ^ "sqlite".hash)
      end

      specify "child classes don't implement #from_string" do
        expect { DatabaseAdapter::PostgreSQL.from_string("postgresql") }.to raise_error(NoMethodError)
        expect { DatabaseAdapter::MySQL2.from_string("mysql2") }.to raise_error(NoMethodError)
        expect { DatabaseAdapter::SQLite.from_string("sqlite") }.to raise_error(NoMethodError)
      end

      context "data type verification" do
        specify "MySQL supports binary" do
          expect(DatabaseAdapter::MySQL2.new("binary").data_type).to eq("binary")
        end

        specify "MySQL supports json" do
          expect(DatabaseAdapter::MySQL2.new("json").data_type).to eq("json")
        end

        specify "MySQL doesn't support jsonb" do
          expect { DatabaseAdapter::MySQL2.new("jsonb") }.to raise_error InvalidDataTypeForAdapter,
                      "MySQL2 doesn't support \"jsonb\". Supported types are: binary, json."
        end

        specify "PostgreSQL supports binary" do
          expect(DatabaseAdapter::PostgreSQL.new("binary").data_type).to eq("binary")
        end

        specify "PostgreSQL supports json" do
          expect(DatabaseAdapter::PostgreSQL.new("json").data_type).to eq("json")
        end

        specify "PostgreSQL supports jsonb" do
          expect(DatabaseAdapter::PostgreSQL.new("jsonb").data_type).to eq("jsonb")
        end

        specify "PostgreSQL doesn't support bla" do
          expect { DatabaseAdapter::PostgreSQL.new("kakadudu") }.to raise_error InvalidDataTypeForAdapter,
                      "PostgreSQL doesn't support \"kakadudu\". Supported types are: binary, json, jsonb."
        end

        specify "sqlite supports binary" do
          expect(DatabaseAdapter::SQLite.new("binary").data_type).to eq("binary")
        end

        specify "sqlite doesn't support json" do
          expect { DatabaseAdapter::SQLite.new("json") }.to raise_error InvalidDataTypeForAdapter,
                      "SQLite doesn't support \"json\". Supported types are: binary."
        end

        specify "sqlite doesn't support jsonb" do
          expect { DatabaseAdapter::SQLite.new("jsonb") }.to raise_error InvalidDataTypeForAdapter,
                      "SQLite doesn't support \"jsonb\". Supported types are: binary."
        end
      end
    end
  end
end
