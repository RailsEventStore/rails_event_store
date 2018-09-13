GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = ruby_event_store
REQUIRE     = $(GEM_NAME)
IGNORE      = RubyEventStore::InMemoryRepository\#append_with_synchronize \
              RubyEventStore::Client::Within\#add_thread_subscribers \
              RubyEventStore::Client::Within\#add_thread_global_subscribers \
              RubyEventStore::Client::Within\#call \
              RubyEventStore::Mappers::InMemoryEncryptionKeyRepository\#prepare_encrypt \
              RubyEventStore::Mappers::EncryptionKey\#prepare_encrypt \
              RubyEventStore::Mappers::EncryptionKey\#prepare_decrypt

SUBJECT     ?= RubyEventStore*

include ../lib/install.mk
include ../lib/test.mk
include ../lib/mutant.mk
include ../lib/gem.mk
include ../lib/help.mk
