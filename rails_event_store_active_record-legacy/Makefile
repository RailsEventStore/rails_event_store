GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = rails_event_store_active_record-legacy
REQUIRE      = rails_event_store_active_record/legacy
IGNORE       =
SUBJECT      ?= RailsEventStoreActiveRecord::Legacy*
DATABASE_URL ?= sqlite3::memory:

include ../lib/install.mk
include ../lib/test.mk
include ../lib/mutant.mk
include ../lib/gem.mk
include ../lib/help.mk

install: install-gemfiles

remove-lock: remove-lockfiles

install-gemfiles:
	@BUNDLE_GEMFILE=../lib/Gemfile.0_18_2 bundle install

remove-lockfiles:
	-rm ../lib/Gemfile.0_18_2.lock