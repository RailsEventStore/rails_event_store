GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = ruby_event_store
REQUIRE     = $(GEM_NAME)
IGNORE      = RubyEventStore::InMemoryRepository\#append_with_synchronize \
              RubyEventStore::InMemoryRepository\#normalize_to_array \
              RubyEventStore::Client\#normalize_to_array \
              RubyEventStore::Client::Within\#normalize_to_array \
              RubyEventStore::Client::Within\#add_thread_subscribers \
              RubyEventStore::Client::Within\#add_thread_global_subscribers \
              RubyEventStore::Client::Within\#call
SUBJECT     ?= RubyEventStore*

include ../lib/install.mk
include ../lib/test.mk
include ../lib/mutant.mk
include ../lib/gem.mk
include ../lib/help.mk
