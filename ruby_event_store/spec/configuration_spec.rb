require "spec_helper"
require "ruby_event_store/configuration"

module RubyEventStore
  ::RSpec.describe Configuration do
    specify { expect(RubyEventStore::Configuration.new.load_defaults("2.17.0").loaded_defaults).to eq("2.17.0") }
    specify { expect(RubyEventStore::Configuration.new.loaded_defaults).to eq(RubyEventStore::VERSION) }
    specify { expect(RubyEventStore::Configuration.new.test).to eq("current_value") }
    specify { expect(RubyEventStore::Configuration.new.load_defaults("1.0.0").test).to eq("current_value") }
    specify { expect(RubyEventStore::Configuration.new.load_defaults("2.17.0").test).to eq("new_value") }
    specify { expect(RubyEventStore::Configuration.new.load_defaults("2.20.0").test).to eq("new_value") }

    specify { expect(RubyEventStore.configuration).to be_a(RubyEventStore::Configuration) }
    specify do
      RubyEventStore.configure do |config|
        config.load_defaults("2.0.0")
        config.test = "another_value"
      end
      expect(RubyEventStore.configuration.loaded_defaults).to eq("2.0.0")
      expect(RubyEventStore.configuration.test).to eq("another_value")
    end
  end
end
