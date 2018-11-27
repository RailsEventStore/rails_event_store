GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = rails_event_store-rspec
REQUIRE     = rails_event_store/rspec
IGNORE      = RailsEventStore::RSpec::Matchers\#differ \
              RailsEventStore::RSpec::Matchers\#formatter \
              RailsEventStore::RSpec::Matchers\#have_published \
              RailsEventStore::RSpec::Matchers\#have_applied \
              RailsEventStore::RSpec::Matchers\#publish \
              RailsEventStore::RSpec::Matchers\#be_an_event \
              RailsEventStore::RSpec::Publish\#last_event
SUBJECT     ?= RailsEventStore::RSpec*

include ../lib/install.mk
include ../lib/test.mk
include ../lib/mutant.mk
include ../lib/gem.mk
include ../lib/help.mk
