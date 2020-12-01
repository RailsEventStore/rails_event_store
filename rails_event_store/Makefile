GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = rails_event_store
REQUIRE     = $(GEM_NAME)
IGNORE      = RailsEventStore::Client\#initialize \
              RailsEventStore::AfterCommitAsyncDispatcher::AsyncRecord* \
              RailsEventStore::AfterCommitAsyncDispatcher\#async_record
SUBJECT      ?= RailsEventStore*
DATABASE_URL ?= sqlite3::memory:

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk
