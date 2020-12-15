require 'ruby_event_store/rspec'

warn <<~EOW
  The 'rails_event_store-rspec' gem has been renamed.

  Please change your Gemfile or gemspec
  to reflect its new name:

    'ruby_event_store-rspec'

EOW

RailsEventStore::RSpec = RubyEventStore::RSpec
