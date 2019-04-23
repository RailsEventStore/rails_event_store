GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = bounded_context
REQUIRE     = $(GEM_NAME)
IGNORE      =
SUBJECT     ?= BoundedContext*

include ../lib/make/install.mk
include ../lib/make/test.mk
include ../lib/make/mutant.mk
include ../lib/make/gem.mk
include ../lib/make/help.mk
