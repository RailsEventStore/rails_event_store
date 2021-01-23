require 'spec_helper'

module RubyEventStore
  RSpec.describe 'no warnings', mutant: false do
    specify do
      expect(ruby_event_store_sidekiq_scheduler_warnings).to eq([])
    end

    def ruby_event_store_sidekiq_scheduler_warnings
      warnings.select { |w| w =~ %r{lib/ruby_event_store/sidekiq_scheduler} }
    end

    def warnings
      `ruby -Ilib -w lib/ruby_event_store/sidekiq_scheduler.rb 2>&1`.split("\n")
    end
  end
end
