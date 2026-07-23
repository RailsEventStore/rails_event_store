# frozen_string_literal: true

require "spec_helper"
require "digest"

module RubyEventStore
  ::RSpec.describe Browser do
    describe ".fingerprint" do
      specify "embeds 8-character MD5 digest of file content as a query parameter" do
        name = "ruby_event_store_browser.js"
        content = File.binread(File.join(Browser::ASSETS_ROOT, name))
        expected = "ruby_event_store_browser.js?v=#{Digest::MD5.hexdigest(content)[0, 8]}"
        expect(Browser.fingerprint(name)).to eq(expected)
      end

      specify "preserves extension" do
        expect(Browser.fingerprint("ruby_event_store_browser.css")).to include(".css")
      end

      specify "different files produce different fingerprints" do
        expect(Browser.fingerprint("ruby_event_store_browser.js")).not_to eq(
          Browser.fingerprint("ruby_event_store_browser.css"),
        )
      end

      specify "splits on first dot so multi-dot extensions are preserved" do
        allow(File).to receive(:binread).and_return("content")
        expect(Browser.fingerprint("archive.tar.gz")).to start_with("archive.tar.gz?v=")
      end
    end
  end
end
