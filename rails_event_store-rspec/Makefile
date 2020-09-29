GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = rails_event_store-rspec
REQUIRE     = rails_event_store/rspec
IGNORE      = RailsEventStore::RSpec::Matchers\#differ \
              RailsEventStore::RSpec::Matchers\#formatter \
              RailsEventStore::RSpec::Matchers\#have_published \
              RailsEventStore::RSpec::Matchers\#have_applied \
              RailsEventStore::RSpec::Matchers\#publish \
              RailsEventStore::RSpec::Matchers\#be_an_event \
              RailsEventStore::RSpec::Publish\#last_event \
              RailsEventStore::RSpec::HaveApplied\#description \
              RailsEventStore::RSpec::HavePublished\#description \
              RailsEventStore::RSpec::HaveApplied\#initialize \
              RailsEventStore::RSpec::HavePublished\#initialize \
              RailsEventStore::RSpec::Matchers::ListPhraser.all_but_last


SUBJECT      ?= RailsEventStore::RSpec*
DATABASE_URL ?= sqlite3::memory:

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk
