GEM_VERSION = $(shell cat ../RES_VERSION)
GEM_NAME    = ruby_event_store
REQUIRE     = $(GEM_NAME)
IGNORE      = RubyEventStore::InMemoryRepository\#with_synchronize \
              RubyEventStore::Client\#default_clock \
              RubyEventStore::Client\#default_correlation_id_generator \
              RubyEventStore::Client::Within\#add_thread_subscribers \
              RubyEventStore::Client::Within\#add_thread_global_subscribers \
              RubyEventStore::Client::Within\#call \
              RubyEventStore::Mappers::InMemoryEncryptionKeyRepository\#prepare_encrypt \
              RubyEventStore::Mappers::EncryptionKey\#prepare_encrypt \
              RubyEventStore::Mappers::EncryptionKey\#prepare_decrypt \
              RubyEventStore::Mappers::EncryptionKey\#prepare_auth_data \
              RubyEventStore::Mappers::EncryptionKey\#encrypt_authenticated \
              RubyEventStore::Mappers::EncryptionKey\#ciphertext_from_authenticated \
              RubyEventStore::Mappers::ForgottenData* \
              RubyEventStore::Subscriptions* \
              RubyEventStore::TransformKeys.transform \
              RubyEventStore::TransformKeys.symbolize \
              RubyEventStore::TransformKeys.stringify

SUBJECT     ?= RubyEventStore*

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk
