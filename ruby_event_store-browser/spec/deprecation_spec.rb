# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    specify do
      expect {
        Browser::App.for(
          event_store_locator: -> { event_store },
          environment: :test
        )
      }.to output(<<~EOS).to_stderr
          Passing :environment to RubyEventStore::Browser::App.for is deprecated. 

          This option is no-op, has no effect and will be removed in next major release.
      EOS
    end

    specify do
      expect {
        Browser::App.for(
          event_store_locator: -> { event_store },
          host: "http://localhost:31337"
        )
      }.to output(<<~EOS).to_stderr
          Passing :host to RubyEventStore::Browser::App.for is deprecated. 

          This option will be removed in next major release. 
          
          Host and mount points are correctly recognized from Rack environment 
          and this option is redundant.
      EOS
    end

    specify do
      expect {
        Browser::App.for(event_store_locator: -> { event_store }, path: "/res")
      }.to output(<<~EOS).to_stderr
          Passing :path to RubyEventStore::Browser::App.for is deprecated. 

          This option will be removed in next major release. 

          Host and mount points are correctly recognized from Rack environment 
          and this option is redundant.
      EOS
    end

    let(:event_store) { Client.new }
  end
end
