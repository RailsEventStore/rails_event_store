# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/generators/rails_event_store/browser_views_generator"

module RailsEventStore
  module Generators
    ::RSpec.describe BrowserViewsGenerator do
      include GeneratorHelper

      around do |example|
        prepare_destination_root
        example.call
        nuke_destination_root
      end

      def run_generator(args = [])
        SilenceStdout.silence_stdout { BrowserViewsGenerator.start(args, destination_root: destination_root) }
      end

      specify "copies every browser view verbatim" do
        run_generator

        views = Dir.glob("**/*.erb", base: RubyEventStore::Browser::Renderer::VIEWS_ROOT)
        expect(views).not_to be_empty
        views.each do |view|
          copy = File.join(destination_root, "app/views/ruby_event_store_browser", view)
          expect(File.exist?(copy)).to eq(true), "expected #{view} to be copied"
          expect(File.read(copy)).to eq(File.read(File.join(RubyEventStore::Browser::Renderer::VIEWS_ROOT, view)))
        end
      end
    end
  end
end
