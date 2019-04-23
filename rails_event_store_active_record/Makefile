GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = rails_event_store_active_record
REQUIRE      = $(GEM_NAME)
IGNORE       = RailsEventStoreActiveRecord::IndexViolationDetector\#detect \
               RailsEventStoreActiveRecord::PgLinearizedEventRepository* \
               RailsEventStoreActiveRecord::EventRepository\#update_messages
SUBJECT      ?= RailsEventStoreActiveRecord*
DATABASE_URL ?= sqlite3::memory:

include ../lib/make/install.mk
include ../lib/make/test.mk
include ../lib/make/mutant.mk
include ../lib/make/gem.mk
include ../lib/make/help.mk

install: install-gemfiles

remove-lock: remove-lockfiles

install-gemfiles:
	@BUNDLE_GEMFILE=../lib/bundler/Gemfile.0_33_0 bundle check || BUNDLE_GEMFILE=../lib/bundler/Gemfile.0_33_0 bundle install
	@BUNDLE_GEMFILE=../lib/bundler/Gemfile.0_34_0 bundle check || BUNDLE_GEMFILE=../lib/bundler/Gemfile.0_34_0 bundle install
	@BUNDLE_GEMFILE=../lib/bundler/Gemfile.0_35_0 bundle check || BUNDLE_GEMFILE=../lib/bundler/Gemfile.0_35_0 bundle install

remove-lockfiles:
	-rm ../lib/bundler/Gemfile.0_33_0.lock
	-rm ../lib/bundler/Gemfile.0_34_0.lock
	-rm ../lib/bundler/Gemfile.0_35_0.lock
