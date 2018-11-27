GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = aggregate_root
REQUIRE     = $(GEM_NAME)
IGNORE      = AggregateRoot\#events_enumerator
SUBJECT     ?= AggregateRoot*

include ../lib/install.mk
include ../lib/test.mk
include ../lib/mutant.mk
include ../lib/gem.mk
include ../lib/help.mk
