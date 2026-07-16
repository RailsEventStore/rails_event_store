# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe StreamPrefixPattern do
      describe ".for" do
        it "picks Glob for sqlite" do
          expect(StreamPrefixPattern.for(double(adapter_name: "SQLite"))).to be_a(StreamPrefixPattern::Glob)
        end

        it "picks Like for other adapters" do
          expect(StreamPrefixPattern.for(double(adapter_name: "PostgreSQL"))).to be_a(StreamPrefixPattern::Like)
          expect(StreamPrefixPattern.for(double(adapter_name: "Mysql2"))).to be_a(StreamPrefixPattern::Like)
        end
      end

      describe StreamPrefixPattern::Like do
        subject(:pattern) { StreamPrefixPattern::Like.new }

        specify do
          expect(pattern.condition).to eq("stream LIKE ?")
        end

        specify do
          expect(pattern.bind_value("Stream")).to eq("Stream%")
        end

        specify "escapes LIKE metacharacters in the prefix" do
          expect(pattern.bind_value("50%off")).to eq('50\%off%')
          expect(pattern.bind_value("a_b")).to eq('a\_b%')
        end
      end

      describe StreamPrefixPattern::Glob do
        subject(:pattern) { StreamPrefixPattern::Glob.new }

        specify do
          expect(pattern.condition).to eq("stream GLOB ?")
        end

        specify do
          expect(pattern.bind_value("Stream")).to eq("Stream*")
        end

        specify "escapes GLOB metacharacters in the prefix" do
          expect(pattern.bind_value("a*b?c[d")).to eq("a[*]b[?]c[[]d*")
        end
      end
    end
  end
end
