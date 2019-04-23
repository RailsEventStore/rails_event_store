GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = rails_event_store
REQUIRE     = $(GEM_NAME)
IGNORE      = RailsEventStore::Client\#initialize \
              RailsEventStore::AfterCommitAsyncDispatcher::AsyncRecord\#rolledback!
SUBJECT      ?= RailsEventStore*
DATABASE_URL ?= sqlite3::memory:

include ../lib/make/install.mk
include ../lib/make/test.mk
include ../lib/make/mutant.mk
include ../lib/make/gem.mk
include ../lib/make/help.mk
