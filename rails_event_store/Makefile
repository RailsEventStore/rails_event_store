GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = rails_event_store
REQUIRE     = $(GEM_NAME)
IGNORE      = RailsEventStore::Client\#initialize \
              RailsEventStore::AfterCommitAsyncDispatcher::AsyncRecord\#rolledback! \
              RailsEventStore::AsyncProxyStrategy::AfterCommit* \
              RailsEventStore::ActiveJobDispatcher*
SUBJECT      ?= RailsEventStore*
DATABASE_URL ?= sqlite3::memory:

include ../lib/install.mk
include ../lib/test.mk
include ../lib/mutant.mk
include ../lib/gem.mk
include ../lib/help.mk
