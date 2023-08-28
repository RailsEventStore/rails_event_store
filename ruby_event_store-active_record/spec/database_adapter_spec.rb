# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe DatabaseAdapter do
      specify "equality" do
        expect(DatabaseAdapter.new("postgresql")).to eql(DatabaseAdapter::Postgres.new)
        expect(DatabaseAdapter.new("mysql")).to eql(DatabaseAdapter::MySQL.new)
        expect(DatabaseAdapter.new("sqlite")).to eql(DatabaseAdapter::Sqlite.new)

        expect(DatabaseAdapter.new("postgresql")).to eq(DatabaseAdapter::Postgres.new)
        expect(DatabaseAdapter.new("mysql")).to eq(DatabaseAdapter::MySQL.new)
        expect(DatabaseAdapter.new("sqlite")).to eq(DatabaseAdapter::Sqlite.new)
      end

      specify "does not equal different type" do
        expect(DatabaseAdapter.new("postgresql")).not_to eql("postgresql")
        expect(DatabaseAdapter.new("mysql")).not_to eql("mysql")
        expect(DatabaseAdapter.new("sqlite")).not_to eql("sqlite")
      end

      specify "hash" do
        expect(DatabaseAdapter::Postgres.new.hash).to eql(DatabaseAdapter::Postgres.hash ^ DatabaseAdapter::BIG_NUM)
        expect(DatabaseAdapter::MySQL.new.hash).to eql(DatabaseAdapter::MySQL.hash ^ DatabaseAdapter::BIG_NUM)
        expect(DatabaseAdapter::Sqlite.new.hash).to eql(DatabaseAdapter::Sqlite.hash ^ DatabaseAdapter::BIG_NUM)

        expect(DatabaseAdapter::Postgres.new.hash).to eql(DatabaseAdapter::Postgres.new.hash)
        expect(DatabaseAdapter::MySQL.new.hash).to eql(DatabaseAdapter::MySQL.new.hash)
        expect(DatabaseAdapter::Sqlite.new.hash).to eql(DatabaseAdapter::Sqlite.new.hash)
      end

      specify "different adapters does not compare" do
        expect(DatabaseAdapter.new("postgresql")).not_to eql(DatabaseAdapter.new("mysql"))
      end

      specify "postgis is postgresql flavor" do
        expect(DatabaseAdapter.new("postgis")).to eq(DatabaseAdapter.new("postgresql"))
      end

      specify "raises exception on unsupported adapter" do
        expect { DatabaseAdapter.new("foo") }.to raise_error(ArgumentError, "Unsupported adapter: \"foo\"")
      end

      specify "case insensitive adapter name" do
        expect(DatabaseAdapter.new("PostgreSQL")).to eq(DatabaseAdapter.new("postgresql"))
      end

      specify "junk adapter name" do
        expect{DatabaseAdapter.new(nil)}.to raise_error(ArgumentError, "Unsupported adapter: nil")
        expect{DatabaseAdapter.new(123)}.to raise_error(ArgumentError, "Unsupported adapter: 123")
      end
    end
  end
end
