GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = ruby_event_store-active_record
OLD_GEM_NAME = rails_event_store_active_record

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/help.mk

build push clean:
	@GEM_NAME=$(GEM_NAME) GEM_VERSION=$(GEM_VERSION) $(MAKE) -f ../support/make/gem.mk $@
	@GEM_NAME=$(OLD_GEM_NAME) GEM_VERSION=$(GEM_VERSION) $(MAKE) -f ../support/make/gem.mk $@

