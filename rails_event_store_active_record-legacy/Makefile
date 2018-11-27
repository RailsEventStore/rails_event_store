GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = rails_event_store_active_record-legacy
REQUIRE      = rails_event_store_active_record/legacy
IGNORE       =
SUBJECT      ?= RailsEventStoreActiveRecord::Legacy*
DATABASE_URL ?= sqlite3::memory:

install: ## Install gem dependencies
	@echo "Installing gem dependencies"
	@bundle install
	@BUNDLE_GEMFILE=../lib/Gemfile.0_18_2 bundle install

remove-lock:
	@echo "Removing resolved dependency versions"
	-rm Gemfile.lock
	-rm ../lib/Gemfile.0_18_2.lock

reinstall: remove-lock install ## Removing resolved dependency versions

include ../lib/test.mk
include ../lib/mutant.mk
include ../lib/gem.mk
include ../lib/help.mk

