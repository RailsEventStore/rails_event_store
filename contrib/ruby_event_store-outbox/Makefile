GEM_VERSION  = $(shell cat lib/ruby_event_store/outbox/version.rb | grep VERSION | egrep -o '[0-9]+\.[0-9]+\.[0-9]+')
GEM_NAME     = ruby_event_store-outbox
REQUIRE      = ruby_event_store/outbox ruby_event_store/outbox/cli
IGNORE       = RubyEventStore::Outbox::CLI* \
	RubyEventStore::Outbox::SidekiqScheduler\#call \
	RubyEventStore::Outbox::SidekiqProducer\#call \
	RubyEventStore::Outbox::SidekiqProcessor\#process \
	RubyEventStore::Outbox::SidekiqProcessor\#after_batch \
	RubyEventStore::Outbox::Metrics.from_url \
	RubyEventStore::Outbox::FetchSpecification\#initialize \
	RubyEventStore::Outbox::Consumer::Configuration \
	RubyEventStore::Outbox::Consumer\#run \
	RubyEventStore::Outbox::Consumer\#retrieve_batch \
	RubyEventStore::Outbox::Consumer\#release_lock_for_process \
	RubyEventStore::Outbox::Consumer\#refresh_lock_for_process \
	RubyEventStore::Outbox::Consumer\#prepare_traps \
	RubyEventStore::Outbox::Consumer\#one_loop \
	RubyEventStore::Outbox::Consumer\#obtain_lock_for_process \
	RubyEventStore::Outbox::Consumer\#initiate_graceful_shutdown \
	RubyEventStore::Outbox::Consumer\#initialize \
	RubyEventStore::Outbox::Consumer\#init \
	RubyEventStore::Outbox::Consumer\#handle_split \
	RubyEventStore::Outbox::Consumer::Configuration* \
	RubyEventStore::Outbox::Consumer\#get_remaining_count \
	RubyEventStore::Outbox::Repository*


SUBJECT      ?= RubyEventStore::Outbox*
DATABASE_URL ?= sqlite3::memory:

include ../../support/make/install.mk
include ../../support/make/test.mk
include ../../support/make/mutant.mk
include ../../support/make/gem.mk
include ../../support/make/help.mk

docker-build: ## Build docker image
	@docker build \
		--file Dockerfile \
		--build-arg GEM_VERSION=$(GEM_VERSION) \
		--tag railseventstore/outbox:$(GEM_VERSION) \
		.

docker-push: ## Push docker image
	@DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect railseventstore/outbox:$(GEM_VERSION) > /dev/null || docker push railseventstore/outbox:$(GEM_VERSION)
