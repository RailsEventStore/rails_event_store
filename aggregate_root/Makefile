GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = aggregate_root
REQUIRE     = $(GEM_NAME)
IGNORE      = AggregateRoot\#events_enumerator
SUBJECT     ?= AggregateRoot*

include ../lib/make/install.mk
include ../lib/make/test.mk
include ../lib/make/mutant.mk
include ../lib/make/gem.mk
include ../lib/make/help.mk
