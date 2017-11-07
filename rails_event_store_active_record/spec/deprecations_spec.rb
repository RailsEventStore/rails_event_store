require 'spec_helper'
require 'active_support/core_ext/string/strip'

module RailsEventStoreActiveRecord
  RSpec.describe LegacyEventRepository do
    specify do
      deprecation_warning = <<-MSG.strip_heredoc
        `RailsEventStoreActiveRecord::LegacyEventRepository` has been deprecated.

        Please migrate to new database schema and use `RailsEventStoreActiveRecord::EventRepository`
        instead:

          rails generate rails_event_store_active_record:v1_v2_migration

      MSG
      expect { LegacyEventRepository.new }.to output(deprecation_warning).to_stderr
    end
  end
end
