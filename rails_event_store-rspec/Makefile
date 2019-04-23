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
SUBJECT      ?= RailsEventStore::RSpec*
DATABASE_URL ?= sqlite3::memory:

include ../lib/make/install.mk
include ../lib/make/test.mk
include ../lib/make/mutant.mk
include ../lib/make/gem.mk
include ../lib/make/help.mk
