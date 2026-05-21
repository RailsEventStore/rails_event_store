# frozen_string_literal: true

require "ruby_event_store/deprecations"
RubyEventStore::Deprecations.suppress(:rails_event_store_active_record_renamed)
require "rails_event_store_active_record"
require_relative "rails_event_store/all"
