require 'spec_helper'

module RailsEventStoreActiveRecord
  module Legacy
    RSpec.describe EventRepository do
      specify do
        deprecation_warning = <<~MSG
          `RailsEventStoreActiveRecord::LegacyEventRepository` has been deprecated.

          Please migrate to new database schema and use `RailsEventStoreActiveRecord::EventRepository`
          instead:

            rails generate rails_event_store_active_record:v1_v2_migration

        MSG
        expect { EventRepository.new }.to output(deprecation_warning).to_stderr
      end
    end
  end
end
