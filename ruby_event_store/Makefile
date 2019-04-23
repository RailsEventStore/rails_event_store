GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = ruby_event_store
REQUIRE     = $(GEM_NAME)
IGNORE      = RubyEventStore::InMemoryRepository\#append_with_synchronize \
              RubyEventStore::Client::Within\#add_thread_subscribers \
              RubyEventStore::Client::Within\#add_thread_global_subscribers \
              RubyEventStore::Client::Within\#call \
              RubyEventStore::Mappers::InMemoryEncryptionKeyRepository\#prepare_encrypt \
              RubyEventStore::Mappers::EncryptionKey\#prepare_encrypt \
              RubyEventStore::Mappers::EncryptionKey\#prepare_decrypt \
              RubyEventStore::Mappers::EncryptionKey\#prepare_auth_data \
              RubyEventStore::Mappers::EncryptionKey\#encrypt_authenticated \
              RubyEventStore::Mappers::EncryptionKey\#ciphertext_from_authenticated

SUBJECT     ?= RubyEventStore*

include ../lib/make/install.mk
include ../lib/make/test.mk
include ../lib/make/mutant.mk
include ../lib/make/gem.mk
include ../lib/make/help.mk
