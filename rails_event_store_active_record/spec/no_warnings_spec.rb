require "spec_helper"

module RailsEventStoreActiveRecord
  RSpec.describe "no warnings", mutant: false do
    specify { expect(rails_event_store_active_record_warnings).to eq([]) }

    def rails_event_store_active_record_warnings
      warnings.select { |w| w =~ %r{lib/rails_event_store_active_record} }
    end

    def warnings
      `ruby -Ilib -w lib/rails_event_store_active_record.rb 2>&1`.split("\n")
    end
  end
end
