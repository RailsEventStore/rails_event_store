GEM_VERSION  = $(shell cat lib/ruby_event_store/protobuf/version.rb | grep VERSION | egrep -o '[0-9]+\.[0-9]+\.[0-9]+')
GEM_NAME     = ruby_event_store-protobuf

include ../../support/make/install.mk
include ../../support/make/test.mk
include ../../support/make/mutant.mk
include ../../support/make/gem.mk
include ../../support/make/help.mk
