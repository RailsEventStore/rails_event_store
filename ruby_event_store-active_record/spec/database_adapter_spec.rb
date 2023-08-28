# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe DatabaseAdapter do
      specify "equality" do
        expect(DatabaseAdapter.new("postgresql")).to eql(DatabaseAdapter::PostgreSQL.new)
        expect(DatabaseAdapter.new("mysql2")).to eql(DatabaseAdapter::MySQL2.new)
        expect(DatabaseAdapter.new("sqlite")).to eql(DatabaseAdapter::SQLite.new)

        expect(DatabaseAdapter.new("postgresql")).to eq(DatabaseAdapter::PostgreSQL.new)
        expect(DatabaseAdapter.new("mysql2")).to eq(DatabaseAdapter::MySQL2.new)
        expect(DatabaseAdapter.new("sqlite")).to eq(DatabaseAdapter::SQLite.new)
      end

      specify "does not equal different type" do
        expect(DatabaseAdapter.new("postgresql")).not_to eql("postgresql")
        expect(DatabaseAdapter.new("mysql2")).not_to eql("mysql2")
        expect(DatabaseAdapter.new("sqlite")).not_to eql("sqlite")
      end

      specify "hash" do
        expect(DatabaseAdapter::PostgreSQL.new.hash).to eql(DatabaseAdapter::PostgreSQL.hash ^ DatabaseAdapter::BIG_NUM)
        expect(DatabaseAdapter::MySQL2.new.hash).to eql(DatabaseAdapter::MySQL2.hash ^ DatabaseAdapter::BIG_NUM)
        expect(DatabaseAdapter::SQLite.new.hash).to eql(DatabaseAdapter::SQLite.hash ^ DatabaseAdapter::BIG_NUM)

        expect(DatabaseAdapter::PostgreSQL.new.hash).to eql(DatabaseAdapter::PostgreSQL.new.hash)
        expect(DatabaseAdapter::MySQL2.new.hash).to eql(DatabaseAdapter::MySQL2.new.hash)
        expect(DatabaseAdapter::SQLite.new.hash).to eql(DatabaseAdapter::SQLite.new.hash)
      end

      specify "different adapters does not compare" do
        expect(DatabaseAdapter.new("postgresql")).not_to eql(DatabaseAdapter.new("mysql2"))
      end

      specify "postgis is postgresql flavor" do
        expect(DatabaseAdapter.new("postgis")).to eq(DatabaseAdapter.new("postgresql"))
      end

      specify "raises exception on unsupported adapter" do
        expect { DatabaseAdapter.new("foo") }.to raise_error(UnsupportedAdapter, "Unsupported adapter: \"foo\"")
      end

      specify "case insensitive adapter name" do
        expect(DatabaseAdapter.new("PostgreSQL")).to eq(DatabaseAdapter.new("postgresql"))
      end

      specify "junk adapter name" do
        expect { DatabaseAdapter.new(nil) }.to raise_error(UnsupportedAdapter, "Unsupported adapter: nil")
        expect { DatabaseAdapter.new(123) }.to raise_error(UnsupportedAdapter, "Unsupported adapter: 123")
      end

      specify "unsupported data type" do
        expect { DatabaseAdapter.new("postgresql", "foo") }.to raise_error(InvalidDataTypeForAdapter)
        expect { DatabaseAdapter.new("mysql2", "foo") }.to raise_error(InvalidDataTypeForAdapter)
        expect { DatabaseAdapter.new("sqlite", "foo") }.to raise_error(InvalidDataTypeForAdapter)
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
          expect { DatabaseAdapter::PostgreSQL.new("bla") }.to raise_error InvalidDataTypeForAdapter,
                      "PostgreSQL doesn't support \"bla\". Supported types are: binary, json, jsonb."
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
