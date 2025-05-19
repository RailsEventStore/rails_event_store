# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Browser
    ::RSpec.describe GemSource do
      specify "git source" do
        path =
          "/Users/mostlyobvious/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/bundler/gems/rails_event_store-151d0dfbec24/ruby_event_store-browser/lib"
        source = GemSource.new(with_unrelated_paths(path))

        expect(source.version).to eq("151d0dfbec24")
        expect(source).to be_from_git
      end

      specify "local path source" do
        path = "/Users/mostlyobvious/Code/rails_event_store/ruby_event_store-browser/lib"
        source = GemSource.new(with_unrelated_paths(path))

        expect(source.version).to be_nil
        expect(source).not_to be_from_git
      end

      specify "rubygems source" do
        path = "/Users/mostlyobvious/.rubies/ruby-3.1.2/lib/ruby/gems/3.1.0/gems/ruby_event_store-browser-2.5.1/lib"
        source = GemSource.new(with_unrelated_paths(path))

        expect(source.version).to eq("2.5.1")
        expect(source).not_to be_from_git
      end

      specify "don't crash on Pathname present in $LOAD_PATH" do
        path =
          "/Users/mostlyobvious/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/bundler/gems/rails_event_store-151d0dfbec24/ruby_event_store-browser/lib"
        source = GemSource.new([Pathname.new(random_unrelated_path), path])

        expect(source.version).to eq("151d0dfbec24")
        expect(source).to be_from_git
      end

      specify "don't crash on two–digit number in version string" do
        path = "/Users/mostlyobvious/.rubies/ruby-3.1.2/lib/ruby/gems/3.1.0/gems/ruby_event_store-browser-22.33.44/lib"
        source = GemSource.new(with_unrelated_paths(path))

        expect(source.version).to eq("22.33.44")
        expect(source).not_to be_from_git
      end

      specify "don't crash on current version number" do
        path =
          "/Users/mostlyobvious/.rubies/ruby-3.1.2/lib/ruby/gems/3.1.0/gems/ruby_event_store-browser-#{RubyEventStore::VERSION}/lib"
        source = GemSource.new(with_unrelated_paths(path))

        expect(source.version).to eq(RubyEventStore::VERSION)
        expect(source).not_to be_from_git
      end

      def random_unrelated_path
        "/kaka/dudu"
      end

      def with_unrelated_paths(path)
        [random_unrelated_path, path, "/dudu/kaka"]
      end
    end
  end
end
