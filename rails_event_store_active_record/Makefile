GEM_VERSION  = $(shell cat ../RES_VERSION)
GEM_NAME     = rails_event_store_active_record
REQUIRE      = $(GEM_NAME)
IGNORE       = RailsEventStoreActiveRecord::IndexViolationDetector* \
               RailsEventStoreActiveRecord::PgLinearizedEventRepository* \
               RailsEventStoreActiveRecord::EventRepository\#update_messages \
               RailsEventStoreActiveRecord::WithAbstractBaseClass\#build_event_klass \
               RailsEventStoreActiveRecord::WithAbstractBaseClass\#build_stream_klass

SUBJECT      ?= RailsEventStoreActiveRecord*
DATABASE_URL ?= sqlite3::memory:

include ../support/make/install.mk
include ../support/make/test.mk
include ../support/make/mutant.mk
include ../support/make/gem.mk
include ../support/make/help.mk

