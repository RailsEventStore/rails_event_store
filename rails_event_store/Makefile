GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = rails_event_store
DATABASE_URL ?= sqlite3::memory:
DATA_TYPE    ?= binary

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk
