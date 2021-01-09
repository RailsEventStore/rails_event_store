GEM_VERSION  = $(shell cat lib/minitest/rails_event_store/version.rb | grep VERSION | egrep -o '[0-9]+\.[0-9]+\.[0-9]+')
GEM_NAME     = minitest-rails_event_store

include ../../support/make/install.mk
include ../../support/make/mutant.mk
include ../../support/make/gem.mk
include ../../support/make/help.mk

test:
	@ruby -Ilib test/minitest/rails_event_store_test.rb

.PHONY: test
