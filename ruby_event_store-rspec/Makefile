GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = ruby_event_store-rspec
REQUIRE     = ruby_event_store/rspec
IGNORE      = RubyEventStore::RSpec::Matchers\#differ \
              RubyEventStore::RSpec::Matchers\#formatter \
              RubyEventStore::RSpec::Matchers\#have_published \
              RubyEventStore::RSpec::Matchers\#have_applied \
              RubyEventStore::RSpec::Matchers\#publish \
              RubyEventStore::RSpec::Matchers\#be_an_event \
              RubyEventStore::RSpec::Publish\#last_event \
              RubyEventStore::RSpec::Matchers::ListPhraser.all_but_last

SUBJECT      ?= RubyEventStore::RSpec*
DATABASE_URL ?= sqlite3::memory:

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk
