GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = ruby_event_store-rom
REQUIRE      = $(GEM_NAME)
IGNORE       = RubyEventStore::ROM.setup \
               RubyEventStore::ROM.setup_defaults \
               RubyEventStore::ROM.configure \
               RubyEventStore::ROM.configure_defaults \
               RubyEventStore::ROM::EventRepository\#initialize \
               RubyEventStore::ROM::EventRepository\#handle_not_found_errors \
               RubyEventStore::ROM::EventRepository\#handle_unique_violation_errors \
               RubyEventStore::ROM::EventRepository\#has_event? \
               RubyEventStore::ROM::EventRepository\#last_stream_event \
               RubyEventStore::ROM::Repositories::Events\#find_nonexistent_pks \
               RubyEventStore::ROM::Repositories::StreamEntries\#create_changeset \
               RubyEventStore::ROM::Changesets::CreateStreamEntries::Defaults.included \
               RubyEventStore::ROM::Changesets::CreateEvents::Defaults.included \
               RubyEventStore::ROM::Changesets::UpdateEvents::Defaults.included \
               RubyEventStore::ROM::Env\#handle_error \
               RubyEventStore::ROM::Env\#initialize \
               RubyEventStore::ROM::Env\#register_error_handler \
               RubyEventStore::ROM::Env\#register_unit_of_work_options \
               RubyEventStore::ROM::Env\#unit_of_work \
               RubyEventStore::ROM::UnitOfWork\#call \
               RubyEventStore::ROM::UnitOfWork\#commit! \
               RubyEventStore::ROM::SQL::Relations::StreamEntries\#normalize_stream_name \
               RubyEventStore::ROM::SQL::IndexViolationDetector\#detect \
               RubyEventStore::ROM::SQL::SpecHelper\#initialize \
               RubyEventStore::ROM::SQL::SpecHelper\#has_connection_pooling? \
               RubyEventStore::ROM::SQL::SpecHelper\#close_pool_connection \
               RubyEventStore::ROM::SQL::SpecHelper\#load_gateway_schema \
               RubyEventStore::ROM::SQL::SpecHelper\#establish_gateway_connection \
               RubyEventStore::ROM::SQL::SpecHelper\#drop_gateway_schema \
               RubyEventStore::ROM::SQL::SpecHelper\#close_gateway_connection \
               RubyEventStore::ROM::SQL::SpecHelper\#run_lifecycle \
               RubyEventStore::ROM::SQL::UnitOfWork\#commit! \
               RubyEventStore::ROM::Memory::SpecHelper\#initialize \
               RubyEventStore::ROM::Memory::SpecHelper\#close_pool_connection \
               RubyEventStore::ROM::Memory::SpecHelper\#load_gateway_schema \
               RubyEventStore::ROM::Memory::SpecHelper\#establish_gateway_connection \
               RubyEventStore::ROM::Memory::SpecHelper\#drop_gateway_schema \
               RubyEventStore::ROM::Memory::SpecHelper\#close_gateway_connection \
               RubyEventStore::ROM::Memory::SpecHelper\#run_lifecycle \
               RubyEventStore::ROM::Memory::UnitOfWork\#commit! \
               RubyEventStore::ROM::Memory::Relations::Events\#verify_uniquness! \
               RubyEventStore::ROM::Memory::Relations::StreamEntries\#verify_uniquness! \
               RubyEventStore::ROM::Memory::Relations::StreamEntries\#normalize_stream_name
SUBJECT      ?= RubyEventStore::ROM*
DATABASE_URL ?= sqlite::memory:

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk
