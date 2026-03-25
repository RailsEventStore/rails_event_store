GEM_VERSION  = $(shell cat lib/ruby_event_store/cli/version.rb | grep VERSION | egrep -o '[0-9]+\.[0-9]+\.[0-9]+')
GEM_NAME     = ruby_event_store-cli

include ../../support/make/install.mk
include ../../support/make/gem.mk
include ../../support/make/help.mk

test:
	@bundle exec rspec

.PHONY: test
