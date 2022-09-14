require "spec_helper"

module RubyEventStore
  module Browser
    RSpec.describe GemSource do
      specify "git source" do
        path = "/Users/mostlyobvious/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/bundler/gems/rails_event_store-151d0dfbec24/ruby_event_store-browser/lib"
        source = GemSource.new([path])

        expect(source.version).to eq("151d0dfbec24")
        expect(source).to be_from_git
      end

      specify "local path source" do
        path = "/Users/mostlyobvious/Code/rails_event_store/ruby_event_store-browser/lib"
        source = GemSource.new([path])

        expect(source.version).to be_nil
        expect(source).not_to be_from_git
      end

      specify "rubygems source" do
        path = "/Users/mostlyobvious/.rubies/ruby-3.1.2/lib/ruby/gems/3.1.0/gems/ruby_event_store-browser-2.5.1/lib"
        source = GemSource.new([path])

        expect(source.version).to eq("2.5.1")
        expect(source).not_to be_from_git
      end
    end
  end
end
