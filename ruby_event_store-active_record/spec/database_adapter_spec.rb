# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe DatabaseAdapter do
      specify "equality" do
        expect(DatabaseAdapter.new("postgresql")).to eql(DatabaseAdapter::Postgres)
        expect(DatabaseAdapter.new("mysql")).to eql(DatabaseAdapter::MySQL)
        expect(DatabaseAdapter.new("sqlite")).to eql(DatabaseAdapter::Sqlite)

        expect(DatabaseAdapter.new("postgresql")).to eq(DatabaseAdapter::Postgres)
        expect(DatabaseAdapter.new("mysql")).to eq(DatabaseAdapter::MySQL)
        expect(DatabaseAdapter.new("sqlite")).to eq(DatabaseAdapter::Sqlite)
      end

      specify "does not equal different type" do
        expect(DatabaseAdapter.new("postgresql")).not_to eql("postgresql")
      end

      specify "different adapters does not compare" do
        expect(DatabaseAdapter.new("postgresql")).not_to eql(DatabaseAdapter.new("mysql"))
      end

      specify "postgis is postgresql flavor" do
        expect(DatabaseAdapter.new("postgis")).to eq(DatabaseAdapter.new("postgresql"))
      end
    end
  end
end
