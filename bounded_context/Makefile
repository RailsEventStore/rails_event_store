GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = bounded_context
REQUIRE     = $(GEM_NAME)
IGNORE      =
SUBJECT     ?= BoundedContext*

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk
