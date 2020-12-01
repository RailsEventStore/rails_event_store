GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = rails_event_store_active_record
REQUIRE      = $(GEM_NAME)
IGNORE       = RailsEventStoreActiveRecord::IndexViolationDetector\#detect \
               RailsEventStoreActiveRecord::PgLinearizedEventRepository* \
               RailsEventStoreActiveRecord::EventRepository\#update_messages \
               RailsEventStoreActiveRecord::WithAbstractBaseClass\#build_event_klass \
               RailsEventStoreActiveRecord::WithAbstractBaseClass\#build_stream_klass

SUBJECT      ?= RailsEventStoreActiveRecord*
DATABASE_URL ?= sqlite3::memory:

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk

install: install-gemfiles

remove-lock: remove-lockfiles

install-gemfiles:
	@BUNDLE_GEMFILE=../support/bundler/Gemfile.0_33_0 bundle check || BUNDLE_GEMFILE=../support/bundler/Gemfile.0_33_0 bundle install
	@BUNDLE_GEMFILE=../support/bundler/Gemfile.0_34_0 bundle check || BUNDLE_GEMFILE=../support/bundler/Gemfile.0_34_0 bundle install
	@BUNDLE_GEMFILE=../support/bundler/Gemfile.0_35_0 bundle check || BUNDLE_GEMFILE=../support/bundler/Gemfile.0_35_0 bundle install
	@BUNDLE_GEMFILE=../support/bundler/Gemfile.1_1_1 bundle check  || BUNDLE_GEMFILE=../support/bundler/Gemfile.1_1_1 bundle install

remove-lockfiles:
	-rm ../support/bundler/Gemfile.0_33_0.lock
	-rm ../support/bundler/Gemfile.0_34_0.lock
	-rm ../support/bundler/Gemfile.0_35_0.lock
	-rm ../support/bundler/Gemfile.1_1_1.lock
