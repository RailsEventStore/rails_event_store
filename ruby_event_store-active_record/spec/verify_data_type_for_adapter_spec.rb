# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe VerifyDataTypeForAdapter do
      specify "MySQL supports binary" do
        expect { VerifyDataTypeForAdapter.new.call(DatabaseAdapter::MySQL2.new, "binary") }.not_to raise_error
      end

      specify "MySQL supports json" do
        expect { VerifyDataTypeForAdapter.new.call(DatabaseAdapter::MySQL2.new, "json") }.not_to raise_error
      end

      specify "MySQL doesn't support jsonb" do
        expect { VerifyDataTypeForAdapter.new.call(DatabaseAdapter::MySQL2.new, "jsonb") }.to raise_error InvalidDataTypeForAdapter,
                    "MySQL2 doesn't support jsonb"
      end

      specify "PostgreSQL supports binary" do
        expect { VerifyDataTypeForAdapter.new.call(DatabaseAdapter::PostgreSQL.new, "binary") }.not_to raise_error
      end

      specify "PostgreSQL supports json" do
        expect { VerifyDataTypeForAdapter.new.call(DatabaseAdapter::PostgreSQL.new, "json") }.not_to raise_error
      end

      specify "PostgreSQL supports jsonb" do
        expect { VerifyDataTypeForAdapter.new.call(DatabaseAdapter::PostgreSQL.new, "jsonb") }.not_to raise_error
      end

      specify "PostgreSQL doesn't support bla" do
        expect { VerifyDataTypeForAdapter.new.call(DatabaseAdapter::PostgreSQL.new, "bla") }.to raise_error InvalidDataTypeForAdapter,
                                                                                                            "PostgreSQL doesn't support bla"
      end

      specify "sqlite supports binary" do
        expect { VerifyDataTypeForAdapter.new.call(DatabaseAdapter::SQLite.new, "binary") }.not_to raise_error
      end

      specify "sqlite doesn't support json" do
        expect { VerifyDataTypeForAdapter.new.call(DatabaseAdapter::SQLite.new, "json") }.to raise_error InvalidDataTypeForAdapter,
                                                                                                         "sqlite doesn't support json"
      end

      specify "sqlite doesn't support jsonb" do
        expect { VerifyDataTypeForAdapter.new.call(DatabaseAdapter::SQLite.new, "jsonb") }.to raise_error InvalidDataTypeForAdapter,
                                                                                                          "sqlite doesn't support jsonb"
      end
    end
  end
end
