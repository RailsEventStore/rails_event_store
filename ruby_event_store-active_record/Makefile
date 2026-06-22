GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = ruby_event_store-active_record

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/help.mk

build push clean:
	@GEM_NAME=$(GEM_NAME) GEM_VERSION=$(GEM_VERSION) $(MAKE) -f ../support/make/gem.mk $@

